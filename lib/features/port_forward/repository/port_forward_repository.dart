import '../../../data/local/database_helper.dart';
import '../models/port_forward_model.dart';

class PortForwardRepository {
  Future<void> ensureTable() async {
    final db = await DatabaseHelper.database;
    // Migrate: add allow_lan column if missing
    final tableInfo = await db.rawQuery('PRAGMA table_info(port_forwards)');
    final hasAllowLan = tableInfo.any((col) => col['name'] == 'allow_lan');

    if (tableInfo.isNotEmpty && !hasAllowLan) {
      await db.execute('ALTER TABLE port_forwards ADD COLUMN allow_lan INTEGER NOT NULL DEFAULT 0');
    }

    await db.execute('''
      CREATE TABLE IF NOT EXISTS port_forwards (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        gateway_host TEXT NOT NULL,
        gateway_port INTEGER NOT NULL DEFAULT 22,
        gateway_username TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'local',
        local_port INTEGER NOT NULL,
        remote_host TEXT NOT NULL,
        remote_port INTEGER NOT NULL,
        auto_start INTEGER NOT NULL DEFAULT 0,
        allow_lan INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<List<PortForwardConfig>> getAll() async {
    await ensureTable();
    final db = await DatabaseHelper.database;
    final maps = await db.query('port_forwards', orderBy: 'name ASC');
    return maps.map((m) => PortForwardConfig.fromMap(m)).toList();
  }

  Future<void> insert(PortForwardConfig config) async {
    await ensureTable();
    final db = await DatabaseHelper.database;
    await db.insert('port_forwards', config.toMap());
  }

  Future<void> update(PortForwardConfig config) async {
    final db = await DatabaseHelper.database;
    await db.update('port_forwards', config.toMap(),
        where: 'id = ?', whereArgs: [config.id]);
  }

  Future<void> setAutoStart(String id, bool autoStart) async {
    final db = await DatabaseHelper.database;
    await db.update('port_forwards', {'auto_start': autoStart ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> delete(String id) async {
    final db = await DatabaseHelper.database;
    await db.delete('port_forwards', where: 'id = ?', whereArgs: [id]);
  }
}
