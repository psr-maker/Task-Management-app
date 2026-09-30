import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalWorkLogDB {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;

    final path = join(
      await getDatabasesPath(),
      'worklog.db',
    );

    _db = await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE worklogs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT,
            workDate TEXT NOT NULL,
            workType TEXT NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            locationName TEXT,
            imagePath TEXT NOT NULL,
            isSubmit INTEGER NOT NULL,
            syncStatus TEXT NOT NULL,
            createdAt TEXT NOT NULL,
            outLatitude REAL,
            outLongitude REAL,
            outLocationName TEXT,
            outImagePath TEXT,
            outTime TEXT,
            serverId INTEGER
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE worklogs ADD COLUMN outLatitude REAL');
          await db.execute('ALTER TABLE worklogs ADD COLUMN outLongitude REAL');
          await db.execute('ALTER TABLE worklogs ADD COLUMN outLocationName TEXT');
          await db.execute('ALTER TABLE worklogs ADD COLUMN outImagePath TEXT');
          await db.execute('ALTER TABLE worklogs ADD COLUMN outTime TEXT');
          await db.execute('ALTER TABLE worklogs ADD COLUMN serverId INTEGER');
        }
      },
    );

    return _db!;
  }

  // =====================================================
  // INSERT
  // =====================================================

  static Future<int> insertWorkLog(
    Map<String, dynamic> data,
  ) async {
    final db = await database;

    return await db.insert(
      'worklogs',
      data,
    );
  }

  // =====================================================
  // GET PENDING
  // =====================================================

  static Future<List<Map<String, dynamic>>> getPendingWorkLogs() async {
    final db = await database;

    return await db.query(
      'worklogs',
      where: 'syncStatus = ?',
      whereArgs: ['pending'],
      orderBy: 'createdAt ASC',
    );
  }

  // =====================================================
  // MARK SYNCED
  // =====================================================

  static Future<void> markAsSynced(int id) async {
    final db = await database;

    await db.update(
      'worklogs',
      {
        'syncStatus': 'synced',
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // =====================================================
  // DELETE SYNCED RECORD - OPTIONAL
  // =====================================================

  static Future<void> deleteSynced(int id) async {
    final db = await database;

    await db.delete(
      'worklogs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // =====================================================
  // UPDATE LOCATION NAME
  // =====================================================

  static Future<void> saveCheckOut({
    required int id,
    required double latitude,
    required double longitude,
    required String locationName,
    required String imagePath,
  }) async {
    final db = await database;

    await db.update(
      'worklogs',
      {
        'outLatitude': latitude,
        'outLongitude': longitude,
        'outLocationName': locationName,
        'outImagePath': imagePath,
        'outTime': DateTime.now().toIso8601String(),
        'syncStatus': 'pending',
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> setServerId(int id, int serverId) async {
    final db = await database;

    await db.update(
      'worklogs',
      {'serverId': serverId},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<Map<String, dynamic>?> findPendingByServerId(int serverId) async {
    final db = await database;
    final rows = await db.query(
      'worklogs',
      where: 'syncStatus = ? AND serverId = ?',
      whereArgs: ['pending', serverId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  static Future<void> updateLocationName(int id, String locationName) async {
    final db = await database;

    await db.update(
      'worklogs',
      {
        'locationName': locationName,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> updateOutLocationName(int id, String locationName) async {
    final db = await database;

    await db.update(
      'worklogs',
      {
        'outLocationName': locationName,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}