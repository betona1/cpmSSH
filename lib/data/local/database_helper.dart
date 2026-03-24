import 'package:sqflite_common/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class DatabaseHelper {
  static Database? _database;
  static const String _dbName = 'cpm_ssh_terminal.db';
  static const int _dbVersion = 2;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dir = await getApplicationSupportDirectory();
    final path = p.join(dir.path, _dbName);
    return await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: _dbVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
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
        created_at TEXT NOT NULL,
        tmux_enabled INTEGER NOT NULL DEFAULT 0,
        tmux_session TEXT
      )
    ''');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE servers ADD COLUMN tmux_enabled INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE servers ADD COLUMN tmux_session TEXT');
    }
  }
}
