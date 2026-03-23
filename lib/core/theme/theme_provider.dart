import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.dark;
  String _fontFamily = 'Malgun Gothic';
  double _fontSize = 14.0;
  int _defaultPort = 10022;
  int _keepAliveSeconds = 30;
  int _connectTimeoutSeconds = 10;

  ThemeMode get mode => _mode;
  String get fontFamily => _fontFamily;
  double get fontSize => _fontSize;
  int get defaultPort => _defaultPort;
  int get keepAliveSeconds => _keepAliveSeconds;
  int get connectTimeoutSeconds => _connectTimeoutSeconds;

  bool get isDark => _mode == ThemeMode.dark;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _mode = (prefs.getString('theme_mode') ?? 'dark') == 'light' ? ThemeMode.light : ThemeMode.dark;
    _fontFamily = prefs.getString('font_family') ?? 'Malgun Gothic';
    _fontSize = prefs.getDouble('terminal_font_size') ?? 14.0;
    _defaultPort = prefs.getInt('default_port') ?? 10022;
    _keepAliveSeconds = prefs.getInt('keep_alive_seconds') ?? 30;
    _connectTimeoutSeconds = prefs.getInt('connect_timeout_seconds') ?? 10;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', _mode == ThemeMode.dark ? 'dark' : 'light');
    notifyListeners();
  }

  Future<void> setFontFamily(String family) async {
    _fontFamily = family;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('font_family', family);
    notifyListeners();
  }

  Future<void> setFontSize(double size) async {
    _fontSize = size;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('terminal_font_size', size);
    notifyListeners();
  }

  Future<void> setDefaultPort(int port) async {
    _defaultPort = port;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('default_port', port);
    notifyListeners();
  }

  Future<void> setKeepAlive(int seconds) async {
    _keepAliveSeconds = seconds;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('keep_alive_seconds', seconds);
    notifyListeners();
  }

  Future<void> setConnectTimeout(int seconds) async {
    _connectTimeoutSeconds = seconds;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('connect_timeout_seconds', seconds);
    notifyListeners();
  }

  static const availableFonts = [
    'Malgun Gothic',
    'Consolas',
    'D2Coding',
    'NanumGothicCoding',
    'Cascadia Code',
    'Fira Code',
    'JetBrains Mono',
    'Segoe UI',
  ];
}
