# 여백

> 시 읽기 보조바퀴 — AI가 시를 대신 해석하지 않고, **질문만 던져** 혼자 읽게 만드는 앱

중앙대학교 모바일프로그래밍 팀 프로젝트 (4인) · Flutter + OpenRouter + Firebase

---

## 지금 어디까지

| 단계 | 내용 | 상태 |
| --- | --- | --- |
| **1 · 화면** | 13개 화면과 화면 이동. 가짜 데이터로 처음부터 끝까지 눌러볼 수 있음 | ✅ 완료 (이름 통일: `docs/여백-이름대조표.md`) |
| **2 · 기능** | Firebase Auth · Firestore, 질문 에이전트, 저장 전 잠금, 모델이 쓰는 대조·요약 | ✅ 붙음 (남은 것은 아래 「아직 안 한 것」) |
| 3 · 통합 | 시연 시나리오 점검, APK, 제출 (15주차) | 진행 중 |

`develop` 기준 — `flutter analyze` 0건, `flutter test` **357개 통과**. PR마다 깃허브 액션이 같은 것을 다시 돌린다.

`main`에는 두 번 올렸다 — #19 (중간 점검), #38 (로그인 분기 · 모델이 쓰는 S07·S09 · 공감·프로필 연결 · 네 번째 시).

## 실행

```bash
flutter pub get
flutter run
```

**기본은 진짜 Firebase다.** 앱을 켜면 S01 로그인에서 시작해서, 로그인하면 S13 안내를 지나 홈으로 간다.

Firebase 설정은 **안드로이드용만** 있다 (`lib/firebase_options.dart`). 크롬·윈도우에서는 켜도 가짜 저장소로 돈다.

Firebase 없이 가짜 데이터로 돌릴 때:

```bash
flutter run --dart-define=USE_FIREBASE=false
```

가짜 모드 데모 계정은 `demo@gmail.com` / `yeobaek1`이다.

질문·대조·요약을 모델이 쓰게 하려면 OpenRouter 키를 `--dart-define`으로 넣는다. **키를 코드나 저장소에 절대 쓰지 않는다.**

```bash
flutter run --dart-define=OPENROUTER_API_KEY=<교수님 발급 키>
```

키가 없으면 앱이 죽지 않고 미리 써 둔 질문·문장으로 넘어간다 (기획서 9장 「오프라인·실패 처리」).

쓰는 모델은 `lib/data/settings_options.dart`에 있고 S11에서 고른다 — 질문은 `nvidia/nemotron-3.5-lightning:free`(신중함·느림), 비교는 `dots-studio/dots-3-note-preview:free`(빠름). 둘 다 2026-11-17에 교수님 키로 호출을 확인한 무료 모델이다.

## 검사

```bash
flutter analyze    # 결과가 하나라도 있으면 CI가 실패한다
flutter test
```

Firestore 보안 규칙은 에뮬레이터로 따로 돈다 — `firestore_test/README.md`.

## 문서

기준 문서는 `docs/`에 있다. **기능은 기획서로 확정됐다** — 바꾸려면 팀이 먼저 합의한다.

| 문서 | 내용 |
| --- | --- |
| [`docs/여백-지침서.md`](docs/여백-지침서.md) | 코드 쓸 때 지키는 규칙 한 장 요약. **작업 전에 먼저 읽기** |
| [`docs/여백-기획서최종.md`](docs/여백-기획서최종.md) | 기능 F1~F8, 화면 S01~S12, 에이전트, 데이터, 디자인 토큰. **기준 문서** |
| [`docs/명세서.md`](docs/명세서.md) | 제출용 명세 — 왜 만드는가, 기능, 화면 흐름 |
| [`docs/여백-화면분업.md`](docs/여백-화면분업.md) | 1단계 — 화면과 이동표, 완료 기준 |
| [`docs/여백-코딩분업.md`](docs/여백-코딩분업.md) | 2단계 — 폴더 주인, 계약, 브랜치·PR 규칙 |
| [`docs/여백-네이밍규칙.md`](docs/여백-네이밍규칙.md) | 용어 사전, 클래스·파일·라우트·Firestore 이름 |
| [`docs/여백-이름대조표.md`](docs/여백-이름대조표.md) | 예전 브랜치(part-b · part-d) 이름 → 지금 이름 |

## 제품 원칙

1. **AI는 답을 주지 않는다.** 응답은 항상 질문으로 끝나고 한 번에 하나만 묻는다.
2. **저장이 유일한 잠금 해제 지점이다.** 해석을 저장하기 전에는 전문가 해석·다른 사람의 대화·창작 배경을 볼 수 없다.
3. **평가하지 않는다.** 기준은 교과서가 아니라 시 안의 근거다. 해석의 질로 점수·순위·보상을 주지 않는다.
4. 앱 어디에도 **"정답", "해설", "올바른"** 을 쓰지 않는다.
5. **명조는 시와 사용자 해석, 고딕은 앱.**
6. AI가 사용자가 안 한 말을 지어내지 않는다. 인용은 원문 부분 문자열인지 코드로 검사한다 (`lib/writers/quote_check.dart`, `lib/agent/tools/verify_quote.dart`).

## 화면과 담당

| ID | 화면 | 파일 | 담당 |
| --- | --- | --- | --- |
| S01 | 로그인 | `lib/features/auth/sign_in_screen.dart` | C |
| S02 | 가입 | `lib/features/auth/sign_up_screen.dart` | C |
| S13 | 안내 (로그인 다음, 홈 앞 · 30초면 저절로 넘어감) | `lib/features/intro/intro_screen.dart` | D |
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

하단 탭바(시 / 모두의 대화 / 설정)는 S03 · S08 · S10에서만 보인다. 라우트 이름은 `lib/app/router.dart` 한 곳에 모여 있다.

## 폴더

```
lib/
├─ main.dart                     C   Firebase 켜기 → 저장소 고르기 → 앱
├─ firebase_options.dart             안드로이드용 설정 (파일만, 비밀값은 커밋 안 함)
├─ app/
│  ├─ router.dart                C   라우트 · 화면 이동
│  ├─ auth_gate.dart             C   로그인 분기 (앱 시작 관문)
│  ├─ tab_shell.dart             C   하단 탭바
│  ├─ theme.dart                 A   색 · 글꼴 (디자인 토큰은 여기서만)
│  └─ strings.dart               전원 화면 문구 (자기 화면 줄만)
├─ data/                         C
│  ├─ repositories.dart              저장소를 한 곳에서 갈아끼운다 (useFakes / useFirebase)
│  ├─ repositories/                  인터페이스 — 화면은 이것만 본다
│  ├─ models/                        Poem, Reading, ExpertInterpretation, Settings …
│  ├─ fakes/                         메모리 가짜 저장소 + fake_data.dart
│  ├─ firestore/                     진짜 Firestore · Firebase Auth 구현
│  └─ local/                         설정은 기기 저장소(SharedPreferences)
├─ agent/                        A   질문 에이전트 — OpenRouter 호출, 출력 검사,
│                                   툴(verify_quote · search_poem_lines), 폴백 질문
├─ writers/                      D   모델이 쓰는 글 — S07 비교 문장 · S09 대화 요약,
│                                   인용 검사(quote_check), 프롬프트, 실패 폴백
├─ compare/                      D   내 해석 ↔ 전문가 해석 관계 계산, 전문가 해석 파서
├─ ports/                        D   D 화면(S07·S08·S09·S12)이 데이터를 읽는 창구
├─ rewards/                      D   저장이 만들어 내는 것 — 새 뱃지 · 공개 대화 (규칙만,
│                                   호출은 C의 저장소 트랜잭션 안에서)
├─ shared/widgets/
│  ├─ poem_view.dart             B   시 본문 (S04 · S05 · S07 공용)
│  ├─ app_loading.dart           D   공용 로딩 (마스코트 16장 · LOADING 파도)
│  └─ 버튼 · 입력칸 · 카드 · 말풍선 · 글자수  A
└─ features/                     화면 (위 표의 담당)

assets/poems/*.json              시 본문 · 전문가 해석 · 뱃지 (한 세트)
assets/badges/                   뱃지 이미지 — 아직 비었다 (없으면 아이콘으로 대신 보인다)
assets/mascot/                   로딩 마스코트 16장
assets/images/                   계절 테마 — 머리 띠 · 마스코트 · 로고 · 질감 · 선반
assets/fonts/                    나눔명조 · Noto Sans KR (SIL OFL)
firestore.rules                  서버 규칙 · firestore_test/가 에뮬레이터로 검사한다
docs/                            기준 문서
```

## 협업 규칙

- 브랜치: `main` ← `develop` ← `feat/<영역>-<설명>`. PR은 항상 `develop`으로, **1명 이상 승인**, squash merge
- PR마다 깃허브 액션이 `flutter analyze` · `flutter test` · 보안 규칙 테스트를 돌린다 (`.github/workflows/ci.yml`)
- 자기 폴더 밖은 고치지 않는다. 필요하면 주인에게 요청하거나 작은 PR로 제안. 주인은 `.github/CODEOWNERS`에 있고 자기 영역이 바뀌는 PR에 리뷰 요청이 자동으로 간다
- `pubspec.yaml` · `router.dart` 변경은 **그것만 담은 작은 PR**로
- 색 · 글꼴은 `theme.dart`, 화면 문구는 `strings.dart`. 화면 파일에 색 코드나 한국어 문구를 직접 쓰지 않는다
- 행 번호는 **1부터** 센다 (`lines[lineNo - 1]`)
- 창작 배경은 `context`가 아니라 `creationBackground`
- 비밀값(OpenRouter 키, `google-services.json`)은 커밋하지 않는다. 실수로 올렸으면 바로 교수님께 키 재발급 요청
- 커밋 메시지: `feat:` `fix:` `refactor:` `docs:` `chore:` + 한국어 설명

## 아직 안 한 것

- **뱃지 이미지** (`assets/badges/{poemId}.png`) — 폴더가 비어 있어서 지금은 시마다 아이콘으로 대신 보인다 (`lib/features/profile/badge_image.dart`)
- **모델 이름** — `dots-studio/dots-3-note-preview:free`는 preview라 내려갈 수 있다. 바뀌면 `lib/data/settings_options.dart`만 고친다
- **3단계** — 시연 시나리오 점검, 릴리스 APK, 제출

## 수록 작품

저작권이 만료된 시만 싣는다 — 윤동주 「서시」, 김소월 「진달래꽃」, 이장희 「봄은 고양이로다」, Robert Frost 「The Road Not Taken」(1916). 저작권이 살아 있는 현대시는 싣지 않는다.

시 하나를 추가할 때 **본문 · 전문가 해석 · 뱃지가 한 세트**다 (`assets/poems/<poemId>.json` · `assets/badges/<poemId>.png`).
