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

  // macOS Keychain은 -34018 에러가 있어서 SharedPreferences 사용
  // Windows/Linux는 flutter_secure_storage가 안정적이므로 그대로 사용
  static bool get _useSharedPrefs =>
      defaultTargetPlatform == TargetPlatform.macOS;

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

  /// 기존 SharedPreferences 데이터를 flutter_secure_storage로 마이그레이션
  static Future<void> migrateFromSharedPrefs() async {
    if (_useSharedPrefs) return; // macOS는 여전히 SharedPreferences 사용
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('_sec_')).toList();
    for (final prefKey in keys) {
      final encoded = prefs.getString(prefKey);
      if (encoded == null) continue;
      final realKey = prefKey.substring(5); // '_sec_' 제거
      String value;
      try {
        value = utf8.decode(base64Decode(encoded));
      } catch (_) {
        value = encoded;
      }
      // flutter_secure_storage로 복사
      await _storage.write(key: realKey, value: value);
      // 마이그레이션 후 SharedPreferences에서 제거
      await prefs.remove(prefKey);
    }
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
