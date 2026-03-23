import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();

  static Future<void> savePassword(String serverId, String password) async {
    await _storage.write(key: 'server_${serverId}_password', value: password);
  }

  static Future<String?> getPassword(String serverId) async {
    return await _storage.read(key: 'server_${serverId}_password');
  }

  static Future<void> savePrivateKey(String serverId, String pem) async {
    await _storage.write(key: 'server_${serverId}_privatekey', value: pem);
  }

  static Future<String?> getPrivateKey(String serverId) async {
    return await _storage.read(key: 'server_${serverId}_privatekey');
  }

  static Future<void> deleteCredentials(String serverId) async {
    await _storage.delete(key: 'server_${serverId}_password');
    await _storage.delete(key: 'server_${serverId}_privatekey');
  }
}
