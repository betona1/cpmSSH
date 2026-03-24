import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart' as sqflite_mobile;
import 'core/theme/theme_provider.dart';
import 'data/local/secure_storage.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux) {
    // 데스크톱: FFI 사용
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  } else {
    // 모바일(iOS/Android): 네이티브 sqflite 팩토리 명시적 설정
    databaseFactory = sqflite_mobile.databaseFactory;
  }

  // 기존 SharedPreferences 비밀번호를 secure storage로 마이그레이션
  await SecureStorageService.migrateFromSharedPrefs();

  final themeProvider = ThemeProvider();
  await themeProvider.load();

  FlutterError.onError = (details) {
    // macOS 한글 입력 시 KeyDownEvent 중복 버그 무시 (Flutter 알려진 이슈)
    final msg = details.exception.toString();
    if (msg.contains('pressedKeys.containsKey')) return;
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
  };

  runApp(CpmSshTerminalApp(themeProvider: themeProvider));
}
