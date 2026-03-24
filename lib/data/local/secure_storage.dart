import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

/// macOS에서 Keychain -34018 에러가 발생하므로
/// macOS/데스크톱: SharedPreferences + base64 인코딩 사용
/// 모바일: FlutterSecureStorage (네이티브 Keychain/Keystore) 사용
class SecureStorageService {
  static const _storage = FlutterSecureStorage();

  static bool get _useSharedPrefs =>
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux;

  // --- Write ---
  static Future<void> savePassword(String serverId, String password) async {
    await _write('server_${serverId}_password', password);
  }

  static Future<void> savePrivateKey(String serverId, String pem) async {
    await _write('server_${serverId}_privatekey', pem);
  }

  // --- Read ---
  static Future<String?> getPassword(String serverId) async {
    return await _read('server_${serverId}_password');
  }

  static Future<String?> getPrivateKey(String serverId) async {
    return await _read('server_${serverId}_privatekey');
  }

  // --- Delete ---
  static Future<void> deleteCredentials(String serverId) async {
    await _delete('server_${serverId}_password');
    await _delete('server_${serverId}_privatekey');
  }

  // --- Internal ---
  static Future<void> _write(String key, String value) async {
    if (_useSharedPrefs) {
      final prefs = await SharedPreferences.getInstance();
      final encoded = base64Encode(utf8.encode(value));
      await prefs.setString('_sec_$key', encoded);
    } else {
      await _storage.write(key: key, value: value);
    }
  }

  static Future<String?> _read(String key) async {
    if (_useSharedPrefs) {
      final prefs = await SharedPreferences.getInstance();
      final encoded = prefs.getString('_sec_$key');
      if (encoded == null) return null;
      try {
        return utf8.decode(base64Decode(encoded));
      } catch (_) {
        return encoded; // fallback: 이전에 평문으로 저장된 경우
      }
    } else {
      return await _storage.read(key: key);
    }
  }

  static Future<void> _delete(String key) async {
    if (_useSharedPrefs) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('_sec_$key');
    } else {
      await _storage.delete(key: key);
    }
  }
}
