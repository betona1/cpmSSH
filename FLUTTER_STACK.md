# Flutter 기술 스택 (FLUTTER_STACK)

## pubspec.yaml

```yaml
name: cpm_ssh_terminal
description: CPM과 통합된 Claude Code 전용 SSH 터미널

environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: '>=3.10.0'

dependencies:
  flutter:
    sdk: flutter

  # SSH 연결
  dartssh2: ^2.9.0          # SSH2 클라이언트

  # 터미널 에뮬레이터
  xterm: ^3.4.0              # xterm 터미널 위젯

  # 상태관리
  flutter_bloc: ^8.1.3       # BLoC 패턴
  equatable: ^2.0.5          # 상태 비교

  # 네트워크
  http: ^1.1.0               # CPM REST API
  web_socket_channel: ^2.4.0 # CPM WebSocket

  # 로컬 저장소
  sqflite: ^2.3.0            # SQLite (서버 프로필)
  flutter_secure_storage: ^9.0.0  # SSH 키/비밀번호 암호화
  shared_preferences: ^2.2.0 # 앱 설정

  # 라우팅
  go_router: ^12.0.0         # 화면 라우팅

  # UI
  flutter_svg: ^2.0.7        # SVG 아이콘
  google_fonts: ^6.1.0       # JetBrains Mono 폰트
  flex_color_scheme: ^7.3.1  # 테마 시스템

  # 유틸리티
  intl: ^0.18.1              # 날짜 포맷
  path_provider: ^2.1.1      # 파일 경로
  file_picker: ^6.1.1        # SSH 키 파일 선택
  url_launcher: ^6.2.1       # 웹서비스 브라우저 열기

dev_dependencies:
  flutter_test:
    sdk: flutter
  bloc_test: ^9.1.5
  mocktail: ^1.0.1
  flutter_lints: ^3.0.0
```

---

## 핵심 패키지 설명

### dartssh2 — SSH 연결
```dart
import 'package:dartssh2/dartssh2.dart';

final client = SSHClient(
  await SSHSocket.connect(host, port),
  username: username,
  onPasswordRequest: () => password,
  identities: [
    // SSH 키 인증
    ...SSHKeyPair.fromPem(privateKeyPem),
  ],
);

// 터미널 세션
final session = await client.shell(
  pty: SSHPtyConfig(
    width: 80,
    height: 24,
    type: 'xterm-256color',
  ),
);
```

### xterm — 터미널 에뮬레이터
```dart
import 'package:xterm/xterm.dart';

final terminal = Terminal(maxLines: 10000);

// SSH 스트림 연결
session.stdout.listen((data) {
  terminal.write(String.fromCharCodes(data));
});
terminal.onOutput = (data) {
  session.stdin.add(utf8.encode(data));
};

// 위젯
TerminalView(terminal)
```

### flutter_bloc — 상태관리
```dart
// SSH 상태
abstract class SshState extends Equatable {}
class SshDisconnected extends SshState {}
class SshConnecting extends SshState {}
class SshConnected extends SshState {
  final SSHClient client;
  final Terminal terminal;
}
class SshError extends SshState {
  final String message;
}

// BLoC
class SshBloc extends Bloc<SshEvent, SshState> {
  SshBloc() : super(SshDisconnected()) {
    on<SshConnect>(_onConnect);
    on<SshDisconnect>(_onDisconnect);
  }
}
```

### flutter_secure_storage — 키 암호화 저장
```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const storage = FlutterSecureStorage();

// SSH 비밀번호 저장
await storage.write(key: 'server_${id}_password', value: password);

// SSH 키 저장
await storage.write(key: 'server_${id}_privatekey', value: pemContent);

// 읽기
final password = await storage.read(key: 'server_${id}_password');
```

---

## 디렉토리 구조

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   └── terminal_theme.dart
│   └── router/
│       └── app_router.dart
├── features/
│   ├── ssh/
│   │   ├── bloc/
│   │   │   ├── ssh_bloc.dart
│   │   │   ├── ssh_event.dart
│   │   │   └── ssh_state.dart
│   │   ├── screens/
│   │   │   ├── terminal_screen.dart
│   │   │   └── multi_tab_screen.dart
│   │   ├── widgets/
│   │   │   ├── terminal_view.dart
│   │   │   ├── mobile_keyboard_toolbar.dart
│   │   │   └── tab_bar.dart
│   │   └── services/
│   │       └── ssh_service.dart
│   ├── servers/
│   │   ├── bloc/
│   │   ├── screens/
│   │   │   ├── server_list_screen.dart
│   │   │   └── server_edit_screen.dart
│   │   ├── models/
│   │   │   └── server_profile.dart
│   │   └── repository/
│   │       └── server_repository.dart
│   ├── cpm/
│   │   ├── bloc/
│   │   ├── screens/
│   │   │   ├── cpm_dashboard_screen.dart
│   │   │   └── prompt_history_screen.dart
│   │   ├── widgets/
│   │   │   ├── prompt_list.dart
│   │   │   ├── token_usage_card.dart
│   │   │   └── service_port_table.dart
│   │   └── services/
│   │       ├── cpm_api_service.dart
│   │       └── cpm_websocket_service.dart
│   └── projects/
│       ├── bloc/
│       ├── screens/
│       │   └── project_list_screen.dart
│       ├── models/
│       │   └── project_config.dart
│       └── repository/
│           └── project_repository.dart
├── shared/
│   ├── widgets/
│   │   ├── loading_widget.dart
│   │   └── error_widget.dart
│   └── utils/
│       ├── ssh_key_utils.dart
│       └── date_utils.dart
└── data/
    ├── local/
    │   ├── database_helper.dart    # SQLite
    │   └── secure_storage.dart     # 키 암호화
    └── remote/
        └── cpm_client.dart         # API 클라이언트
```

---

## 빌드 명령어

```bash
# 개발 실행
flutter run

# Android APK
flutter build apk --release

# Android App Bundle (Play Store)
flutter build appbundle --release

# iOS (Mac 필요)
flutter build ios --release

# Windows
flutter build windows --release

# macOS (Mac 필요)
flutter build macos --release
```

---

## 개발 환경 설정

```bash
# Flutter 설치 확인
flutter doctor

# 의존성 설치
flutter pub get

# 코드 생성 (freezed 등 사용 시)
dart run build_runner build

# 테스트
flutter test

# 린트
flutter analyze
```
