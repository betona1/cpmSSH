import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static Database? _database;
  static const String _dbName = 'cpm_ssh_terminal.db';
  static const int _dbVersion = 1;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    sqfliteFfiInit();
    final databaseFactory = databaseFactoryFfi;
    final dir = await getApplicationSupportDirectory();
    final path = '${dir.path}/$_dbName';
    return await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: _dbVersion,
        onCreate: _onCreate,
      ),
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE servers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        host TEXT NOT NULL,
        port INTEGER NOT NULL DEFAULT 22,
        username TEXT NOT NULL,
        auth_method TEXT NOT NULL DEFAULT 'password',
        group_name TEXT,
        initial_dir TEXT,
        init_command TEXT,
        cpm_project_id INTEGER,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        last_connected_at TEXT,
        created_at TEXT NOT NULL
      )
    ''');
  }
}
