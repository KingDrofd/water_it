import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

/// Owns the on-disk copies of plant photos.
///
/// Paths coming from `image_picker` point into the OS cache, which can be
/// reclaimed at any time — every image referenced by a saved plant must be
/// copied into app-owned storage.
abstract class PlantImageStore {
  /// Copies any externally-located images into this plant's directory and
  /// returns the resulting path list (already-persisted paths pass through
  /// unchanged). Files in the plant's directory that are no longer
  /// referenced are deleted.
  Future<List<String>> persistImages(String plantId, List<String> paths);

  /// Removes every stored image for the plant.
  Future<void> deleteImages(String plantId);

  /// Root directory holding one subdirectory of images per plant.
  Directory get baseDir;
}

class PlantImageStoreImpl implements PlantImageStore {
  PlantImageStoreImpl(this._baseDir);

  final Directory _baseDir;

  @override
  Directory get baseDir => _baseDir;
  static const Uuid _uuid = Uuid();

  Directory _plantDir(String plantId) =>
      Directory(p.join(_baseDir.path, plantId));

  @override
  Future<List<String>> persistImages(
    String plantId,
    List<String> paths,
  ) async {
    final dir = _plantDir(plantId);
    final result = <String>[];

    for (final path in paths) {
      if (p.isWithin(dir.path, path)) {
        result.add(path);
        continue;
      }
      final source = File(path);
      if (!await source.exists()) {
        // Source is gone (e.g. cache already cleared) — keep the reference
        // rather than silently dropping the user's image slot.
        result.add(path);
        continue;
      }
      await dir.create(recursive: true);
      final target = p.join(dir.path, '${_uuid.v4()}${p.extension(path)}');
      await source.copy(target);
      result.add(target);
    }

    if (await dir.exists()) {
      final kept = result.map(p.canonicalize).toSet();
      await for (final entity in dir.list()) {
        if (entity is File && !kept.contains(p.canonicalize(entity.path))) {
          await entity.delete();
        }
      }
    }

    return result;
  }

  @override
  Future<void> deleteImages(String plantId) async {
    final dir = _plantDir(plantId);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }
}
