# 시스템 아키텍처

## 전체 구성도

```
┌─────────────────────────────────────────────────────────┐
│                  CPM SSH Terminal App                    │
│              (Flutter Cross-Platform)                    │
├───────────────┬─────────────────┬───────────────────────┤
│   Android     │     iOS         │  Windows / macOS       │
└───────┬───────┴────────┬────────┴──────────┬────────────┘
        │                │                   │
        └────────────────┼───────────────────┘
                         │
          ┌──────────────┼──────────────┐
          │              │              │
    ┌─────▼─────┐  ┌─────▼─────┐  ┌───▼──────────┐
    │  SSH 연결  │  │ CPM API   │  │  로컬 DB      │
    │ dartssh2  │  │ REST/WS   │  │  SQLite       │
    └─────┬─────┘  └─────┬─────┘  └──────────────┘
          │              │
    ┌─────▼─────┐  ┌─────▼──────────────────────┐
    │  원격 서버 │  │  CPM 서버 (Django :9200)   │
    │  SSH:22   │  │  /api/projects/            │
    │  Claude   │  │  /api/prompts/             │
    │  Code     │  │  /api/terminals/           │
    └───────────┘  │  /api/services/            │
                   │  ws://... (WebSocket)      │
                   └────────────────────────────┘
```

---

## 레이어 아키텍처

```
┌─────────────────────────────────┐
│         Presentation Layer       │
│  Flutter Widgets / Screens       │
│  - SshTerminalScreen            │
│  - CpmDashboardScreen           │
│  - ServerListScreen             │
│  - ProjectScreen                │
├─────────────────────────────────┤
│         BLoC / Provider Layer    │
│  상태관리 (flutter_bloc)         │
│  - SshBloc                      │
│  - CpmBloc                      │
│  - ServerBloc                   │
│  - PromptBloc                   │
├─────────────────────────────────┤
│         Service Layer            │
│  - SshService (dartssh2)        │
│  - CpmApiService (http)         │
│  - CpmWebSocketService          │
│  - LocalStorageService          │
├─────────────────────────────────┤
│         Data Layer               │
│  - ServerRepository             │
│  - PromptRepository             │
│  - ProjectRepository            │
│  Local: SQLite / SharedPrefs    │
│  Remote: CPM REST API           │
└─────────────────────────────────┘
```

---

## 데이터 흐름

### SSH 접속 흐름
```
사용자 → 서버 선택
       → SshBloc.connect(server)
       → SshService.connect(host, port, user, key)
       → dartssh2 SSH 연결 수립
       → xterm 터미널 스트림 연결
       → 화면에 터미널 렌더링
```

### CPM 프롬프트 전송 흐름
```
사용자 → 프롬프트 입력
       → PromptBloc.send(prompt, projectId)
       → CpmApiService.POST /api/prompts/
       → SSH 채널로 Claude Code에 전송
       → CPM hook → DB 자동 저장
       → WebSocket으로 실시간 업데이트
```

### 프로젝트 원클릭 접속 흐름
```
사용자 → 프로젝트 탭 선택
       → ProjectBloc.activate(project)
       → 저장된 SSH 세팅 로드
       → SshService.connect()
       → CPM API → 해당 프로젝트 컨텍스트 로드
       → 터미널 + CPM 대시보드 동시 표시
```

---

## 모듈 구성

```
lib/
├── main.dart
├── app.dart                    # 앱 진입점, 라우팅
├── core/
│   ├── constants.dart          # 상수 (포트, URL 등)
│   ├── theme.dart              # 앱 테마
│   └── router.dart             # GoRouter 라우팅
├── features/
│   ├── ssh/                    # SSH 터미널 기능
│   │   ├── bloc/
│   │   ├── screens/
│   │   ├── widgets/
│   │   └── services/
│   ├── cpm/                    # CPM 연동 기능
│   │   ├── bloc/
│   │   ├── screens/
│   │   ├── widgets/
│   │   └── services/
│   ├── servers/                # 서버 관리
│   │   ├── bloc/
│   │   ├── screens/
│   │   ├── models/
│   │   └── repository/
│   └── projects/               # 프로젝트 관리
│       ├── bloc/
│       ├── screens/
│       ├── models/
│       └── repository/
├── shared/
│   ├── widgets/                # 공통 위젯
│   ├── models/                 # 공통 모델
│   └── utils/                  # 유틸리티
└── data/
    ├── local/                  # SQLite, SharedPrefs
    └── remote/                 # CPM API 클라이언트
```

---

## 플랫폼별 고려사항

| 항목 | Android | iOS | Windows | macOS |
|------|---------|-----|---------|-------|
| SSH 라이브러리 | dartssh2 | dartssh2 | dartssh2 | dartssh2 |
| 터미널 | xterm (flutter) | xterm (flutter) | xterm (flutter) | xterm (flutter) |
| 로컬 DB | SQLite | SQLite | SQLite | SQLite |
| 키체인 | Keystore | Keychain | WinCredential | Keychain |
| 배포 | Play Store / APK | App Store / IPA | exe / MSIX | dmg |
| 비용 | 무료 | $99/년 | 무료 | $99/년 |

---

## 보안 아키텍처

```
SSH 키 관리
├── 플랫폼 키체인 저장 (flutter_secure_storage)
├── 앱 내 평문 저장 금지
└── 비밀번호 암호화 저장

CPM API 통신
├── 로컬 네트워크 전용 (기본)
├── 외부 접속 시 HTTPS 권장
└── API 토큰 인증 (추후)

SSH 연결
├── Password / PublicKey 모두 지원
├── Host Key Verification
└── Keep-alive 설정
```
