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
      version: 1,
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
            createdAt TEXT NOT NULL
          )
        ''');
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
}