import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:water_it/features/plants/data/datasources/plant_image_store.dart';

/// What a backup zip contains, read without importing it. Shown to the user
/// before the replace-all confirmation.
class BackupSummary {
  const BackupSummary({
    required this.format,
    this.exportedAt,
    required this.plantCount,
    required this.roomCount,
    required this.careTaskCount,
    required this.careEventCount,
    required this.imageCount,
  });

  final int format;
  final DateTime? exportedAt;
  final int plantCount;
  final int roomCount;
  final int careTaskCount;
  final int careEventCount;
  final int imageCount;
}

/// Builds and restores the manual backup zip: `data.json` (all tables +
/// settings, format-versioned) plus `images/<plantId>/<file>`.
class BackupService {
  BackupService(this._db, this._imageStore);

  static const int formatVersion = 1;
  static const String _dataFile = 'data.json';
  static const String _imagesPrefix = 'images/';

  final Database _db;
  final PlantImageStore _imageStore;

  Future<Uint8List> exportArchive() async {
    final plants = await _db.query('plants');
    final rooms = await _db.query('rooms');
    final careTasks = await _db.query('care_tasks');
    final careEvents = await _db.query('care_events');
    final settings = await _readSettings();

    final archive = Archive();
    var imageCount = 0;

    for (final plant in plants) {
      final paths = _decodeImagePaths(plant['image_paths']);
      for (final path in paths) {
        final file = File(path);
        if (!await file.exists()) {
          continue;
        }
        final bytes = await file.readAsBytes();
        archive.addFile(ArchiveFile(
          '$_imagesPrefix${plant['id']}/${p.basename(path)}',
          bytes.length,
          bytes,
        ));
        imageCount++;
      }
    }

    final data = jsonEncode({
      'format': formatVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'imageCount': imageCount,
      'plants': plants,
      'rooms': rooms,
      'careTasks': careTasks,
      'careEvents': careEvents,
      'settings': settings,
    });
    final dataBytes = utf8.encode(data);
    archive.addFile(ArchiveFile(_dataFile, dataBytes.length, dataBytes));

    return Uint8List.fromList(ZipEncoder().encode(archive)!);
  }

  /// Parses the zip's `data.json` without touching any state. Returns null
  /// when the file isn't a Water It backup.
  static BackupSummary? readSummary(Uint8List zipBytes) {
    final data = _decodeData(zipBytes);
    if (data == null) {
      return null;
    }
    final format = data['format'];
    if (format is! int) {
      return null;
    }
    return BackupSummary(
      format: format,
      exportedAt: DateTime.tryParse(data['exportedAt'] as String? ?? ''),
      plantCount: (data['plants'] as List<dynamic>? ?? []).length,
      roomCount: (data['rooms'] as List<dynamic>? ?? []).length,
      careTaskCount: (data['careTasks'] as List<dynamic>? ?? []).length,
      careEventCount: (data['careEvents'] as List<dynamic>? ?? []).length,
      imageCount: data['imageCount'] as int? ?? 0,
    );
  }

  /// Replaces ALL app data with the zip's contents. Callers confirm with
  /// the user first (via [readSummary]).
  Future<void> importArchive(Uint8List zipBytes) async {
    final archive = ZipDecoder().decodeBytes(zipBytes);
    final data = _decodeData(zipBytes);
    if (data == null) {
      throw const FormatException('Not a Water It backup file.');
    }
    final format = data['format'];
    if (format is! int || format < 1) {
      throw const FormatException('Not a Water It backup file.');
    }
    if (format > formatVersion) {
      throw const FormatException(
        'This backup was made by a newer version of Water It. Update the app '
        'and try again.',
      );
    }

    // Zip image entries: plantId -> basename -> bytes.
    final imagesByPlant = <String, Map<String, List<int>>>{};
    for (final file in archive.files) {
      if (!file.isFile || !file.name.startsWith(_imagesPrefix)) {
        continue;
      }
      final parts = p.posix.split(file.name.substring(_imagesPrefix.length));
      if (parts.length != 2) {
        continue;
      }
      imagesByPlant.putIfAbsent(parts[0], () => {})[parts[1]] =
          file.content as List<int>;
    }

    final baseDir = _imageStore.baseDir;

    await _db.transaction((txn) async {
      await txn.delete('care_events');
      await txn.delete('care_tasks');
      await txn.delete('plants');
      await txn.delete('rooms');

      for (final row in _rows(data['rooms'])) {
        await txn.insert('rooms', row,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final row in _rows(data['plants'])) {
        final plantId = row['id'] as String? ?? '';
        row['image_paths'] = jsonEncode(
          _restoredImagePaths(
            _decodeImagePaths(row['image_paths']),
            imagesByPlant[plantId] ?? const {},
            p.join(baseDir.path, plantId),
          ),
        );
        await txn.insert('plants', row,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final row in _rows(data['careTasks'])) {
        await txn.insert('care_tasks', row,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final row in _rows(data['careEvents'])) {
        await txn.insert('care_events', row,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });

    // DB committed — now swap the image store to match it.
    if (await baseDir.exists()) {
      await baseDir.delete(recursive: true);
    }
    for (final entry in imagesByPlant.entries) {
      final plantDir = Directory(p.join(baseDir.path, entry.key));
      await plantDir.create(recursive: true);
      for (final image in entry.value.entries) {
        await File(p.join(plantDir.path, image.key))
            .writeAsBytes(image.value);
      }
    }

    await _restoreSettings(data['settings']);
  }

  static Map<String, dynamic>? _decodeData(Uint8List zipBytes) {
    try {
      final archive = ZipDecoder().decodeBytes(zipBytes);
      final entry = archive.files.where(
        (f) => f.isFile && f.name == _dataFile,
      );
      if (entry.isEmpty) {
        return null;
      }
      final decoded =
          jsonDecode(utf8.decode(entry.first.content as List<int>));
      return decoded is Map<String, dynamic> ? decoded : null;
    } on Object {
      return null;
    }
  }

  static List<Map<String, dynamic>> _rows(Object? value) {
    if (value is! List) {
      return const [];
    }
    return [
      for (final row in value)
        if (row is Map) Map<String, dynamic>.from(row),
    ];
  }

  static List<String> _decodeImagePaths(Object? json) {
    if (json is! String || json.isEmpty) {
      return const [];
    }
    try {
      return List<String>.from(jsonDecode(json) as List<dynamic>);
    } on FormatException {
      return const [];
    }
  }

  /// Maps a plant's exported image paths onto the restored files, keeping
  /// order and dropping images the zip doesn't contain.
  static List<String> _restoredImagePaths(
    List<String> originalPaths,
    Map<String, List<int>> restored,
    String plantDirPath,
  ) {
    return [
      for (final path in originalPaths)
        if (restored.containsKey(p.basename(path)))
          p.join(plantDirPath, p.basename(path)),
    ];
  }

  Future<Map<String, Object?>> _readSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {for (final key in prefs.getKeys()) key: prefs.get(key)};
  }

  Future<void> _restoreSettings(Object? settings) async {
    if (settings is! Map) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    for (final entry in settings.entries) {
      final key = entry.key as String;
      final value = entry.value;
      switch (value) {
        case bool v:
          await prefs.setBool(key, v);
        case int v:
          await prefs.setInt(key, v);
        case double v:
          await prefs.setDouble(key, v);
        case String v:
          await prefs.setString(key, v);
        case List v:
          await prefs.setStringList(key, v.cast<String>());
      }
    }
  }
}
