import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Owns the SQLite schema: DDL, creation, and version migrations.
///
/// Schema history:
///   v1  plants + watering_reminders
///   v2  plants.use_random_image
///   v3  watering_reminders.weekdays
///   v4  rooms, care_tasks, care_events; plants.room_id;
///       watering_reminders migrated into care_tasks (type 'water') and dropped
///   v5  plants.care_notes; lighting/watering/soil free text canonicalized to
///       enum names (unmatched text preserved in care_notes)
///   v6  care_tasks.created_at, so a new task is never treated as already
///       overdue for due moments that predate it
class AppDatabase {
  AppDatabase._();

  static const int version = 6;

  static const createRoomTable = '''
CREATE TABLE IF NOT EXISTS rooms(
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  is_outdoor INTEGER NOT NULL DEFAULT 0,
  sort_order INTEGER NOT NULL DEFAULT 0
);
''';

  static const createPlantTable = '''
CREATE TABLE IF NOT EXISTS plants(
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  age_months INTEGER,
  description TEXT,
  origin TEXT,
  soil_type TEXT,
  preferred_lighting TEXT,
  watering_level TEXT,
  care_notes TEXT,
  scientific_name TEXT,
  image_paths TEXT,
  use_random_image INTEGER NOT NULL DEFAULT 0,
  room_id TEXT REFERENCES rooms(id) ON DELETE SET NULL
);
''';

  static const createCareTaskTable = '''
CREATE TABLE IF NOT EXISTS care_tasks(
  id TEXT PRIMARY KEY,
  plant_id TEXT NOT NULL REFERENCES plants(id) ON DELETE CASCADE,
  type TEXT NOT NULL DEFAULT 'water',
  custom_label TEXT,
  schedule_type TEXT NOT NULL DEFAULT 'weekly',
  weekdays TEXT,
  interval_days INTEGER NOT NULL DEFAULT 0,
  preferred_time TEXT,
  notes TEXT,
  active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT
);
''';

  static const createCareEventTable = '''
CREATE TABLE IF NOT EXISTS care_events(
  id TEXT PRIMARY KEY,
  plant_id TEXT NOT NULL REFERENCES plants(id) ON DELETE CASCADE,
  task_id TEXT,
  type TEXT NOT NULL,
  completed_at TEXT NOT NULL,
  note TEXT,
  source TEXT NOT NULL DEFAULT 'manual'
);
''';

  static Future<void> createSchema(DatabaseExecutor db) async {
    await db.execute(createRoomTable);
    await db.execute(createPlantTable);
    await db.execute(createCareTaskTable);
    await db.execute(createCareEventTable);
  }

  static Future<void> migrate(
    DatabaseExecutor db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE plants ADD COLUMN use_random_image INTEGER NOT NULL DEFAULT 0',
      );
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE watering_reminders ADD COLUMN weekdays TEXT',
      );
    }
    if (oldVersion < 4) {
      await db.execute(createRoomTable);
      await db.execute(createCareTaskTable);
      await db.execute(createCareEventTable);
      await db.execute(
        'ALTER TABLE plants ADD COLUMN room_id TEXT REFERENCES rooms(id) ON DELETE SET NULL',
      );
      // A reminder with chosen weekdays becomes a weekly task; one without
      // becomes an interval task driven by its old frequency_days.
      await db.execute('''
INSERT INTO care_tasks (
  id, plant_id, type, schedule_type, weekdays,
  interval_days, preferred_time, notes, active
)
SELECT
  id,
  plant_id,
  'water',
  CASE
    WHEN weekdays IS NOT NULL AND weekdays != '' AND weekdays != '[]'
      THEN 'weekly'
    ELSE 'interval'
  END,
  weekdays,
  frequency_days,
  preferred_time,
  notes,
  1
FROM watering_reminders
''');
      await db.execute('DROP TABLE watering_reminders');
    }
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE plants ADD COLUMN care_notes TEXT');
      await _canonicalizeCareFields(db);
    }
    if (oldVersion < 6) {
      // Upgrades that also ran the v4 step already got the column, because
      // that step builds care_tasks from the current DDL.
      if (!await _hasColumn(db, 'care_tasks', 'created_at')) {
        await db.execute('ALTER TABLE care_tasks ADD COLUMN created_at TEXT');
      }
      // Existing tasks get "now" rather than a backdated value: it gives every
      // task a clean slate instead of carrying forward a phantom overdue state
      // from before the column existed.
      await db.rawUpdate(
        'UPDATE care_tasks SET created_at = ? WHERE created_at IS NULL',
        [DateTime.now().toIso8601String()],
      );
    }
  }

  /// Whether [table] already has [column]; migrations that may run after a
  /// step which recreates the table from current DDL must check first.
  static Future<bool> _hasColumn(
    DatabaseExecutor db,
    String table,
    String column,
  ) async {
    final rows = await db.rawQuery('PRAGMA table_info($table)');
    return rows.any((row) => row['name'] == column);
  }

  /// Best-effort v5 conversion of free-text care fields into enum names.
  /// Text that doesn't match any vocabulary is preserved in care_notes so
  /// nothing the user typed is lost.
  static Future<void> _canonicalizeCareFields(DatabaseExecutor db) async {
    final rows = await db.query(
      'plants',
      columns: ['id', 'preferred_lighting', 'watering_level', 'soil_type'],
    );
    for (final row in rows) {
      final leftovers = <String>[];

      String? convert(String column, String? Function(String) match) {
        final raw = (row[column] as String?)?.trim();
        if (raw == null || raw.isEmpty) {
          return null;
        }
        final canonical = match(raw.toLowerCase());
        if (canonical == null) {
          leftovers.add(raw);
        }
        return canonical;
      }

      final lighting = convert('preferred_lighting', _matchLighting);
      final watering = convert('watering_level', _matchWatering);
      final soil = convert('soil_type', _matchSoil);

      await db.update(
        'plants',
        {
          'preferred_lighting': lighting,
          'watering_level': watering,
          'soil_type': soil,
          if (leftovers.isNotEmpty) 'care_notes': leftovers.join('\n'),
        },
        where: 'id = ?',
        whereArgs: [row['id']],
      );
    }
  }

  static String? _matchLighting(String raw) {
    if (raw.contains('full') || raw.contains('direct sun')) return 'fullSun';
    if (raw.contains('bright')) return 'brightIndirect';
    if (raw.contains('low') || raw.contains('shade')) return 'lowLight';
    if (raw.contains('medium') ||
        raw.contains('indirect') ||
        raw.contains('partial')) {
      return 'mediumIndirect';
    }
    if (raw.contains('sun')) return 'fullSun';
    return null;
  }

  static String? _matchWatering(String raw) {
    if (raw.contains('frequent') ||
        raw.contains('high') ||
        raw.contains('heavy') ||
        raw.contains('daily')) {
      return 'frequent';
    }
    if (raw.contains('moderate') ||
        raw.contains('medium') ||
        raw.contains('regular') ||
        raw.contains('weekly')) {
      return 'moderate';
    }
    if (raw.contains('low') ||
        raw.contains('light') ||
        raw.contains('sparse') ||
        raw.contains('minimal')) {
      return 'low';
    }
    return null;
  }

  static String? _matchSoil(String raw) {
    if (raw.contains('cact') ||
        raw.contains('succulent') ||
        raw.contains('sand')) {
      return 'cactusMix';
    }
    if (raw.contains('orchid') || raw.contains('bark')) return 'orchidMix';
    if (raw.contains('drain')) return 'wellDraining';
    if (raw.contains('all') ||
        raw.contains('potting') ||
        raw.contains('general') ||
        raw.contains('loam')) {
      return 'allPurpose';
    }
    return null;
  }

  static Future<Database> open() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'water_it.db');

    return openDatabase(
      path,
      version: version,
      onCreate: (db, _) => createSchema(db),
      onUpgrade: migrate,
    );
  }
}
