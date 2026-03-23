import '../../../data/local/database_helper.dart';
import '../../../data/local/secure_storage.dart';
import '../models/server_profile.dart';

class ServerRepository {
  Future<List<ServerProfile>> getAll() async {
    final db = await DatabaseHelper.database;
    final maps = await db.query('servers', orderBy: 'is_favorite DESC, name ASC');
    return maps.map((m) => ServerProfile.fromMap(m)).toList();
  }

  Future<ServerProfile?> getById(String id) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query('servers', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return ServerProfile.fromMap(maps.first);
  }

  Future<void> insert(ServerProfile server, {String? password, String? privateKey}) async {
    final db = await DatabaseHelper.database;
    await db.insert('servers', server.toMap());
    if (password != null) {
      await SecureStorageService.savePassword(server.id, password);
    }
    if (privateKey != null) {
      await SecureStorageService.savePrivateKey(server.id, privateKey);
    }
  }

  Future<void> update(ServerProfile server, {String? password, String? privateKey}) async {
    final db = await DatabaseHelper.database;
    await db.update('servers', server.toMap(), where: 'id = ?', whereArgs: [server.id]);
    if (password != null) {
      await SecureStorageService.savePassword(server.id, password);
    }
    if (privateKey != null) {
      await SecureStorageService.savePrivateKey(server.id, privateKey);
    }
  }

  Future<void> delete(String id) async {
    final db = await DatabaseHelper.database;
    await db.delete('servers', where: 'id = ?', whereArgs: [id]);
    await SecureStorageService.deleteCredentials(id);
  }

  Future<void> toggleFavorite(String id, bool isFavorite) async {
    final db = await DatabaseHelper.database;
    await db.update('servers', {'is_favorite': isFavorite ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateLastConnected(String id) async {
    final db = await DatabaseHelper.database;
    await db.update(
      'servers',
      {'last_connected_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
