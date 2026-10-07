# 여백

> 시 읽기 보조바퀴 — AI가 시를 대신 해석하지 않고, **질문만 던져** 혼자 읽게 만드는 앱

중앙대학교 모바일프로그래밍 팀 프로젝트 (4인) · Flutter + OpenRouter + Firebase

---

## 지금 어디까지

| 단계 | 내용 | 상태 |
| --- | --- | --- |
| **1 · 화면** | 12개 화면과 화면 이동. 가짜 데이터로 처음부터 끝까지 눌러볼 수 있음 | ✅ B · D 화면 통합, 이름 통일 완료 (`docs/여백-이름대조표.md`) |
| 2 · 기능 | 같은 담당자가 자기 화면에 기능을 붙임 (Firebase, 에이전트, 잠금) | 대기 |
| 3 · 통합 | 시연 시나리오 점검, APK, 제출 (15주차) | 대기 |

## 실행

```bash
flutter pub get
flutter run
```

앱을 켜면 S01 로그인부터 시작한다. 1단계에서는 아무 값이나 넣고 **로그인**을 누르면 홈으로 간다.

OpenRouter 키는 2단계부터 `--dart-define`으로 넣는다. **키를 코드나 저장소에 절대 쓰지 않는다.**

```bash
flutter run --dart-define=OPENROUTER_API_KEY=<교수님 발급 키>
```

## 문서

기준 문서는 `docs/`에 있다. **기능은 기획서로 확정됐다** — 바꾸려면 팀이 먼저 합의한다.

| 문서 | 내용 |
| --- | --- |
| [`docs/여백-지침서.md`](docs/여백-지침서.md) | 코드 쓸 때 지키는 규칙 한 장 요약. **작업 전에 먼저 읽기** |
| [`docs/여백-기획서최종.md`](docs/여백-기획서최종.md) | 기능 F1~F8, 화면 S01~S12, 에이전트, 데이터, 디자인 토큰. **기준 문서** |
| [`docs/여백-화면분업.md`](docs/여백-화면분업.md) | 1단계 — 화면과 이동표, 완료 기준 |
| [`docs/여백-코딩분업.md`](docs/여백-코딩분업.md) | 2단계 — 폴더 주인, 계약, 브랜치·PR 규칙 (1단계 후 다시 정리) |
| [`docs/여백-네이밍규칙.md`](docs/여백-네이밍규칙.md) | 용어 사전, 클래스·파일·라우트·Firestore 이름 |
| [`docs/여백-이름대조표.md`](docs/여백-이름대조표.md) | 예전 브랜치(part-b · part-d) 이름 → 지금 이름 |

## 제품 원칙

1. **AI는 답을 주지 않는다.** 응답은 항상 질문으로 끝나고 한 번에 하나만 묻는다.
2. **저장이 유일한 잠금 해제 지점이다.** 해석을 저장하기 전에는 전문가 해석·다른 사람의 대화·창작 배경을 볼 수 없다.
3. **평가하지 않는다.** 기준은 교과서가 아니라 시 안의 근거다.
4. 앱 어디에도 **"정답", "해설", "올바른"** 을 쓰지 않는다.
5. **명조는 시와 사용자 해석, 고딕은 앱.**
6. AI가 사용자가 안 한 말을 지어내지 않는다. 인용은 원문 부분 문자열인지 코드로 검사한다.

## 화면과 담당

| ID | 화면 | 파일 | 담당 |
| --- | --- | --- | --- |
| S01 | 로그인 | `lib/features/auth/sign_in_screen.dart` | C |
| S02 | 가입 | `lib/features/auth/sign_up_screen.dart` | C |
| S03 | 홈 | `lib/features/home/home_screen.dart` | B |
| S04 | 읽기 | `lib/features/reading/reading_screen.dart` | B |
| S05 | 대화 | `lib/features/chat/chat_screen.dart` | A |
| S06 | 정리 · 저장 | `lib/features/save/save_screen.dart` | B |
| S07 | 대조 | `lib/features/compare/comparison_screen.dart` | D |
| S08 | 대화 목록 | `lib/features/community/community_list_screen.dart` | D |
| S09 | 대화 보기 | `lib/features/community/community_detail_screen.dart` | D |
| S10 | 설정 보기 | `lib/features/settings/settings_screen.dart` | C |
| S11 | 설정 바꾸기 | `lib/features/settings/settings_edit_screen.dart` | C |
| S12 | 프로필 | `lib/features/profile/profile_screen.dart` | D |

하단 탭바(시 / 모두의 대화 / 설정)는 S03 · S08 · S10에서만 보인다.

## 폴더

```
lib/
├─ main.dart                     C
├─ app/
│  ├─ router.dart                C   라우트 · 화면 이동
│  ├─ tab_shell.dart             C   하단 탭바
│  ├─ theme.dart                 A   색 · 글꼴 (디자인 토큰은 여기서만)
│  └─ strings.dart               전원 화면 문구 (자기 화면 줄만)
├─ data/
│  ├─ models/                    C   Poem, Reading, ExpertInterpretation …
│  └─ fakes/fake_data.dart       1단계 가짜 데이터
├─ compare/relation.dart         D   내 해석 ↔ 전문가 해석 관계 계산
├─ shared/widgets/
│  ├─ poem_view.dart             B   시 본문 (S04 · S05 · S07 공용)
│  ├─ badge_image.dart           D   뱃지 (지금은 아이콘 자리)
│  └─ 버튼 · 입력칸 · 카드 · 말풍선  A
└─ features/                     화면 (위 표의 담당)

assets/fonts/                    나눔명조 · Noto Sans KR (SIL OFL)
docs/                            기준 문서
```

## 협업 규칙

- 브랜치: `main` ← `develop` ← `feat/<영역>-<설명>`. PR은 항상 `develop`으로, **1명 이상 승인**, squash merge
- 자기 폴더 밖은 고치지 않는다. 필요하면 주인에게 요청하거나 작은 PR로 제안
- `pubspec.yaml` · `router.dart` 변경은 **그것만 담은 작은 PR**로
- 색 · 글꼴은 `theme.dart`, 화면 문구는 `strings.dart`. 화면 파일에 색 코드나 한국어 문구를 직접 쓰지 않는다
- 행 번호는 **1부터** 센다 (`lines[lineNo - 1]`)
- 창작 배경은 `context`가 아니라 `creationBackground`
- 비밀값(OpenRouter 키, `google-services.json`)은 커밋하지 않는다. 실수로 올렸으면 바로 교수님께 키 재발급 요청
- 커밋 메시지: `feat:` `fix:` `refactor:` `docs:` `chore:` + 한국어 설명

## 1단계에서 아직 안 한 것 (2단계 몫)

- Firebase Auth · Firestore 연결, 로그인 검증
- 입력 제한 (gmail만, 비밀번호 문자 차단, 글자 수 막기) — 글자 수는 **표시만** 한다
- 저장 전 잠금 — 1단계에서는 **늘 열린 상태**
- 에이전트 (`verify_quote` · `search_poem_lines`), 대조 계산 (`compare_with_experts`)
- 뱃지 이미지 (`assets/badges/{poemId}.png`) — 지금은 아이콘으로 자리만 잡아둠
- 모델 이름 — 교수님 키로 열린 모델 확인 후 확정 (지금은 임시 값)

## 수록 작품

저작권이 만료된 시만 싣는다 — 윤동주 「서시」, 김소월 「진달래꽃」, 이장희 「봄은 고양이로다」. 저작권이 살아 있는 현대시는 싣지 않는다.
