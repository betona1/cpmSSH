# CPM API 연동 가이드 (CPM_INTEGRATION)

## CPM 서버 연결 설정

```dart
// lib/core/constants.dart
class CpmConfig {
  static String baseUrl = 'http://192.168.219.x:9200';
  static String wsUrl = 'ws://192.168.219.x:9200/ws/';
  static int port = 9200;
}
```

---

## REST API 클라이언트

```dart
// lib/data/remote/cpm_client.dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class CpmApiClient {
  final String baseUrl;
  CpmApiClient(this.baseUrl);

  // 프로젝트 목록
  Future<List<Project>> getProjects() async {
    final res = await http.get(Uri.parse('$baseUrl/api/projects/'));
    final data = jsonDecode(res.body) as List;
    return data.map((e) => Project.fromJson(e)).toList();
  }

  // 프롬프트 목록 (프로젝트별)
  Future<List<Prompt>> getPrompts({String? projectId, String? search}) async {
    final params = {
      if (projectId != null) 'project': projectId,
      if (search != null) 'search': search,
    };
    final uri = Uri.parse('$baseUrl/api/prompts/').replace(queryParameters: params);
    final res = await http.get(uri);
    final data = jsonDecode(res.body) as List;
    return data.map((e) => Prompt.fromJson(e)).toList();
  }

  // 프롬프트 전송 (CPM에 저장)
  Future<void> sendPrompt({
    required String content,
    required String projectId,
    String tag = 'other',
  }) async {
    await http.post(
      Uri.parse('$baseUrl/api/prompts/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'content': content,
        'project': projectId,
        'tag': tag,
        'source': 'cpm-ssh-terminal',
      }),
    );
  }

  // 서비스 포트 목록
  Future<List<ServicePort>> getServices() async {
    final res = await http.get(Uri.parse('$baseUrl/api/services/'));
    final data = jsonDecode(res.body) as List;
    return data.map((e) => ServicePort.fromJson(e)).toList();
  }

  // 전체 통계
  Future<Stats> getStats() async {
    final res = await http.get(Uri.parse('$baseUrl/api/stats/'));
    return Stats.fromJson(jsonDecode(res.body));
  }

  // 템플릿 목록
  Future<List<Template>> getTemplates() async {
    final res = await http.get(Uri.parse('$baseUrl/api/templates/'));
    final data = jsonDecode(res.body) as List;
    return data.map((e) => Template.fromJson(e)).toList();
  }
}
```

---

## 데이터 모델

```dart
// lib/features/cpm/models/

// 프로젝트
class Project {
  final int id;
  final String name;
  final String path;
  final String? url;
  final int tokenCount;
  final DateTime updatedAt;

  factory Project.fromJson(Map<String, dynamic> json) => Project(
    id: json['id'],
    name: json['name'],
    path: json['path'] ?? '',
    url: json['url'],
    tokenCount: json['token_count'] ?? 0,
    updatedAt: DateTime.parse(json['updated_at']),
  );
}

// 프롬프트
class Prompt {
  final int id;
  final String content;
  final String status;   // success, fail, pending
  final String tag;      // bug, feature, refactor...
  final int projectId;
  final DateTime createdAt;

  factory Prompt.fromJson(Map<String, dynamic> json) => Prompt(
    id: json['id'],
    content: json['content'],
    status: json['status'] ?? 'pending',
    tag: json['tag'] ?? 'other',
    projectId: json['project'],
    createdAt: DateTime.parse(json['created_at']),
  );
}

// 서비스 포트
class ServicePort {
  final int id;
  final String host;
  final int port;
  final String serviceName;
  final bool isOpen;
  final String? remarks;

  factory ServicePort.fromJson(Map<String, dynamic> json) => ServicePort(
    id: json['id'],
    host: json['host'],
    port: json['port'],
    serviceName: json['service_name'] ?? '',
    isOpen: json['is_open'] ?? false,
    remarks: json['remarks'],
  );
}
```

---

## WebSocket 실시간 연동

```dart
// lib/features/cpm/services/cpm_websocket_service.dart
import 'package:web_socket_channel/web_socket_channel.dart';

class CpmWebSocketService {
  WebSocketChannel? _channel;

  void connect(String wsUrl) {
    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
    _channel!.stream.listen((message) {
      final data = jsonDecode(message);
      // 이벤트 처리
      switch (data['type']) {
        case 'prompt_saved':
          // 프롬프트 저장 → 대시보드 업데이트
          break;
        case 'token_update':
          // 토큰 사용량 업데이트
          break;
      }
    });
  }

  void disconnect() {
    _channel?.sink.close();
  }
}
```

---

## 프로젝트-SSH 연동 설정

```dart
// lib/features/projects/models/project_config.dart
class ProjectConfig {
  final int cpmProjectId;      // CPM 프로젝트 ID
  final String serverProfileId; // SSH 서버 프로필 ID
  final String? initialDir;    // 접속 후 이동할 디렉토리
  final String? initCommand;   // 접속 후 자동 실행 명령어
  final String? displayName;   // 앱에 표시할 이름

  // 예시
  // cpmProjectId: 1 (ai100)
  // serverProfileId: 'server-219-100'
  // initialDir: '/home/ai100'
  // initCommand: 'conda activate ai100'
  // displayName: 'AI100 프로젝트'
}
```

---

## CPM 연결 상태 체크

```dart
// 앱 시작 시 CPM 서버 연결 확인
Future<bool> checkCpmConnection(String baseUrl) async {
  try {
    final res = await http.get(
      Uri.parse('$baseUrl/api/stats/'),
    ).timeout(const Duration(seconds: 5));
    return res.statusCode == 200;
  } catch (e) {
    return false; // 오프라인 모드로 동작
  }
}
```

---

## 오프라인 모드

```
CPM 서버 미연결 시
├── SSH 터미널 기능은 정상 동작
├── CPM 대시보드 → "서버 연결 안됨" 표시
├── 프롬프트 히스토리 → 로컬 캐시 표시
└── 서버 재연결 시 자동 동기화
```
