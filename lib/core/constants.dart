class AppConstants {
  static const String appName = 'CPM SSH Terminal';
  static const String appVersion = '1.0.0';

  // Default SSH settings
  static const int defaultSshPort = 22;
  static const int sshConnectTimeoutSeconds = 10;
  static const int sshKeepAliveIntervalSeconds = 30;
  static const int terminalScrollbackLines = 10000;
  static const String defaultEncoding = 'UTF-8';

  // Terminal defaults
  static const double defaultFontSize = 14.0;
  static const double minFontSize = 10.0;
  static const double maxFontSize = 24.0;
}

class CpmConfig {
  static String baseUrl = 'http://192.168.219.100:9200';
  static String wsUrl = 'ws://192.168.219.100:9200/ws/';
  static int port = 9200;
}
