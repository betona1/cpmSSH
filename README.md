# CPM SSH Terminal

> Claude Code에 최적화된 크로스플랫폼 SSH 터미널 앱  
> Flutter 기반 | Android · iOS · Windows · macOS · Linux

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Windows%20%7C%20macOS-green)]()
[![CPM](https://img.shields.io/badge/CPM-v2.0-orange)](https://github.com/betona1/ClaudePromptManager)

---

## 개요

CPM SSH Terminal은 [Claude Prompt Manager(CPM)](https://github.com/betona1/ClaudePromptManager)와 완벽하게 통합된 SSH 터미널 앱입니다.

- **SSH 접속 관리** — Putty처럼 서버 정보 저장 및 원클릭 접속
- **CPM 통합** — 프롬프트 히스토리, 프로젝트 현황을 앱 내에서 바로 확인
- **Claude Code 최적화** — 프로젝트별 접속 세팅, 프롬프트 빠른 전송
- **크로스플랫폼** — Android, iOS, Windows, macOS 단일 코드베이스

---

## 문서 구조

```
docs/
├── README.md                  # 이 파일
├── ARCHITECTURE.md            # 전체 시스템 아키텍처
├── FEATURES.md                # 기능 명세
├── FLUTTER_STACK.md           # Flutter 기술 스택
├── CPM_INTEGRATION.md         # CPM API 연동 가이드
├── SSH_DESIGN.md              # SSH 터미널 설계
├── UI_DESIGN.md               # UI/UX 설계
└── ROADMAP.md                 # 개발 로드맵
```

---

## 빠른 시작

### 요구사항
- Flutter 3.x 이상
- CPM 서버 실행 중 (`python3 manage.py cpm_web` → port 9200)
- SSH 접속 가능한 서버

### 설치
```bash
git clone https://github.com/betona1/cpm-ssh-terminal.git
cd cpm-ssh-terminal
flutter pub get
flutter run
```

---

## 핵심 기능 요약

| 기능 | 설명 |
|------|------|
| SSH 멀티탭 | 여러 서버 동시 접속 |
| 서버 프로필 | IP/포트/계정/키 저장 |
| CPM 대시보드 | 프롬프트/프로젝트 현황 |
| 프롬프트 전송 | Claude Code에 바로 전송 |
| 프로젝트 연동 | 프로젝트별 SSH 세팅 저장 |
| 원클릭 접속 | 프로젝트 선택 → 즉시 연결 |

---

## 관련 링크

- [CPM GitHub](https://github.com/betona1/ClaudePromptManager)
- [CPM API 문서](http://localhost:9200/api/)
- [Flutter 공식](https://flutter.dev)
