import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _db;

  static Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await initDb();
    return _db!;
  }

  static Future<Database> initDb() async {
    String path = join(await getDatabasesPath(), 'location.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE locations(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            latitude REAL,
            longitude REAL,
            accuracy REAL,
            speed REAL,
            timestamp TEXT
          )
        ''');

        await db.execute('''
CREATE TABLE status_logs(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  internet_status TEXT,
  location_status TEXT,
  timestamp TEXT
)
''');
      },
    );
  }

  // INSERT
  static Future<void> insertLocation(Map<String, dynamic> data) async {
    final dbClient = await db;
    await dbClient.insert('locations', data);
  }

  // GET ALL
  static Future<List<Map<String, dynamic>>> getLocations() async {
    final dbClient = await db;
    return await dbClient.query('locations');
  }

  // DELETE BY ID
  static Future<void> deleteLocation(int id) async {
    final dbClient = await db;
    await dbClient.delete('locations', where: 'id=?', whereArgs: [id]);
  }

  static Future<void> saveStatusLocally(
    String internet, String location) async {
  final dbClient = await db;

  await dbClient.insert('status_logs', {
    'internet_status': internet,
    'location_status': location,
    'timestamp': DateTime.now().toIso8601String(),
  });
}

static Future<void> insertStatus(Map<String, dynamic> data) async {
  final dbClient = await db;
  await dbClient.insert('status_logs', data);
}

// GET STATUS
static Future<List<Map<String, dynamic>>> getStatusLogs() async {
  final dbClient = await db;
  return await dbClient.query('status_logs');
}

// DELETE STATUS
static Future<void> deleteStatus(int id) async {
  final dbClient = await db;
  await dbClient.delete('status_logs', where: 'id=?', whereArgs: [id]);
}
}
