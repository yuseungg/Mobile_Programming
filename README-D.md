# D 파트 합치기 설명서

`feat/part-d-stage0`을 합칠 사람을 위한 문서입니다. **추측이 아니라 실제로 합쳐 보고 측정한 결과**만 적었습니다. 측정 명령은 각 항목 끝에 그대로 적어 두었으니 못 믿으시면 직접 돌려 보세요.

- 브랜치: `feat/part-d-stage0` → PR #8 (`develop` 대상, squash merge)
- 담당 화면: S07 대조 · S08 대화 목록 · S09 대화 보기 · S12 프로필
- 기준: `docs/여백-기획서최종.md` 4장(대조) · 5장(잠금) · 7장(데이터) · 9장(실패 처리)

---

## 1. 결론부터

| | |
| --- | --- |
| 다른 브랜치와의 텍스트 충돌 | **없음** |
| 전부 합친 뒤 `flutter analyze` | 0건 |
| 전부 합친 뒤 `flutter test` | **160개 통과** |
| 합친 뒤 **반드시** 해야 하는 연결 | **3개** (4장) |
| 절대 합치면 안 되는 브랜치 | **2개** (3장) |

합치는 건 쉽습니다. **합친 뒤에 연결을 빼먹는 것이 위험합니다.** 빠뜨리면 빌드도 되고 테스트도 통과하는데 기능이 조용히 죽습니다. 4장이 그 목록입니다.

---

## 2. 무엇이 들어오는가

커밋 14개입니다. 화면 네 개와, 그 화면이 쓰는 것들입니다.

### 고친 것 — 눈에 보이는 변화

| | 전 | 후 |
| --- | --- | --- |
| 서시에서 내 근거 `[6]` 대 전문가 A 근거 `[2,6,7,8]` | 같은 곳을 봤어요 | **같은 줄에서 출발했어요** |
| 관계 배지 색 | 세 관계 모두 초록(`confirmed`) | 세 관계 모두 `AppText.relation` |
| 저장하지 않은 시의 남의 대화 | 자물쇠만 붙고 열렸음 | 목록 대신 잠금 안내 |
| AppBar 제목 | 화면마다 인라인 17/w600 | 테마의 `screenTitle` |
| 전문가 해석 | 코드 안(`FakeData`) | `assets/poems/seosi.json` |
| 읽기 실패 | 스피너가 영원히 돎 | 안내 + 다시 시도 |

관계 규칙은 **한쪽이 다른 쪽을 포함하면 같다고 보던 것**을 기획서 4장 표대로 **집합이 같을 때만**으로 고쳤습니다. 내 근거는 보통 1~2행이고 전문가는 4행이라, 포함을 같음으로 보면 `partialOverlap`이 사실상 나오지 않고 3상태가 2상태로 붕괴합니다.

배지 색은 겹쳤다고 초록을 쓰면 「맞췄다」로 읽힙니다. 기획서 4장은 어느 해석도 정답이 아니라고 못박으므로 세 관계를 같은 색으로 통일했습니다.

### 새로 만든 폴더 셋 — 분업표에 줄 추가가 필요합니다

| 폴더 | 들어 있는 것 | 왜 `lib/compare/`가 아닌가 |
| --- | --- | --- |
| `lib/ports/` | D 화면이 데이터를 읽는 창구(`ReadingSource`)와 가짜 구현 | 화면 네 개가 공유하고, C의 저장소가 끼워질 자리 |
| `lib/rewards/` | 뱃지 지급·공개 대화 생성 규칙 | 분업표의 `lib/compare/` 범위가 "compare_with_experts, get_poem_context, 관계 계산" |
| `lib/writers/` | 비교 문장·요약 생성기와 폴백 | 모델이 글을 쓰는 쪽. 관계 계산과 성격이 다름 |

`lib/compare/`에는 원래 범위대로 `relation.dart` · `compare_tools.dart` · `expert_parser.dart`만 있습니다.

### 경계 — 남의 파일은 건드리지 않았습니다

- `lib/agent/` · `lib/data/` · `lib/app/theme.dart` · `lib/app/router.dart` · `android/` — **손대지 않음**
- `lib/app/strings.dart` — 제 화면 문구만 **추가**. 남의 문구는 고치지 않았습니다 (분업표대로 이 파일은 전원 공용)
- `pubspec.yaml` — `assets:` 두 줄만 추가

---

## 3. 합치는 순서

측정한 결과입니다. `origin/develop`에서 시작해 차례로 머지했습니다.

| 순서 | 브랜치 | 결과 |
| --- | --- | --- |
| 1 | `feat/data-repositories` (C) | 충돌 없음 |
| 2 | `feat/reading-flow` (B) | 충돌 없음 |
| 3 | `feat/home-poem-list` (B) | **충돌 1건** — `test/part_b_test.dart` |
| 4 | `feat/part-d-stage0` (D) | 충돌 없음 |
| 5 | `feat/chat-agent` (A) | 충돌 없음 |

**`fix/reading-max-length`는 따로 합칠 필요가 없습니다.** `feat/reading-flow`가 이미 포함하고 있습니다 (`git merge-base --is-ancestor`로 확인).

### 절대 합치면 안 되는 브랜치 둘

| 브랜치 | 이유 |
| --- | --- |
| `docs/name-mapping` | **2026-10-07** 커밋. 리팩터 이전 구조라 `lib/compare/relation.dart`를 **삭제**합니다 |
| `feature/part-d` | 리팩터 이전 레이아웃(`lib/screens/`, `lib/models/`, `lib/core/`). 합치면 죽은 사본 11개가 되살아납니다 |

둘 다 역할이 끝난 브랜치입니다. 지워도 됩니다.

### 유일한 충돌 1건 — B 내부 문제입니다

`test/part_b_test.dart` 한 파일에서만 부딪힙니다. `feat/reading-flow`와 `feat/home-poem-list`가 같은 흐름 테스트를 서로 다르게 고쳤습니다.

- `reading-flow`: 멈춘 사람 수 기대값을 `12명` → `13명`으로 (다른 사람 12 + 나)
- `home-poem-list`: 오늘의 시가 날마다 바뀌므로, 홈에서 목록의 「서시」를 찾아 누르는 방식으로

**둘 다 살려야 합니다.** 홈에서 서시를 고르는 새 흐름 위에, 멈춘 사람 수 기대값 13을 얹으면 됩니다. D 파일이 아니라 제가 임의로 고치지 않았습니다.

### 측정 방법

```bash
git worktree add --detach /tmp/integ origin/develop
cd /tmp/integ
for b in feat/data-repositories feat/reading-flow feat/home-poem-list \
         feat/part-d-stage0 feat/chat-agent; do
  git merge --no-edit origin/$b || { git diff --name-only --diff-filter=U; git merge --abort; }
done
flutter pub get && flutter analyze && flutter test
```

---

## 4. 합친 뒤 반드시 해야 하는 연결 3개

여기가 이 문서의 핵심입니다. 셋 다 **안 해도 빌드되고 테스트가 통과합니다.** 그래서 잊기 쉽습니다.

### (1) D 화면을 C의 저장소에 잇는다 — 제일 중요

지금 D 화면은 `ReadingSource`의 기본 구현 `FakeReadingSource`를 씁니다. 그것은 `FakeData`의 `static const`를 읽습니다. C의 저장소는 `FakeStore`의 **가변** 사본에 씁니다. **두 경로가 갈라집니다.**

합쳐진 트리에서 실제로 재 봤습니다 — 진달래꽃을 `saveInterpretation`으로 저장한 뒤:

```
저장 후   repo=true                  fakeData=false
뱃지      repo=[seosi, jindallae]    fakeData=[seosi]
```

즉 **어댑터를 끼우지 않으면, 저장해도 S08 잠금이 안 풀리고 S12에 뱃지가 안 생깁니다.** 화면은 멀쩡히 돌아가서 더 위험합니다.

고치는 방법은 파일 하나를 더하고 기본값을 바꾸는 것입니다. 아래 어댑터는 **합쳐진 트리에서 컴파일과 테스트(160개)를 통과하는 것을 확인했습니다.**

`lib/ports/repository_reading_source.dart`:

```dart
// 주인: D — ReadingSource를 C의 저장소로 잇는 어댑터
import '../compare/expert_parser.dart';
import '../data/fakes/fake_data.dart';
import '../data/models/expert_interpretation.dart';
import '../data/models/poem.dart';
import '../data/models/public_conversation.dart';
import '../data/models/reading.dart';
import '../data/models/user_profile.dart';
import '../data/repositories.dart';
import 'reading_source.dart';

class RepositoryReadingSource implements ReadingSource {
  const RepositoryReadingSource();

  @override
  String get myUserId => Repositories.auth.currentUserId ?? '';

  @override
  String get todayPoemId => FakeData.todayPoemId;

  // 시 본문과 미리 쓴 비교 문장은 저장소가 아니라 앱 번들에 있다 (기획서 7장)
  @override
  Future<List<Poem>> poems() async => FakeData.poems;

  @override
  Future<Poem> poemById(String poemId) async => FakeData.poemById(poemId);

  @override
  Future<Reading?> readingFor(String poemId) =>
      Repositories.reading.fetchReading(myUserId, poemId);

  @override
  Future<UserProfile> profileById(String userId) =>
      Repositories.user.fetchProfile(userId);

  @override
  Future<List<PublicConversation>> conversationsFor(String poemId) =>
      Repositories.publicConversation.fetchForPoem(poemId);

  @override
  Future<PublicConversation> conversationById(String conversationId) =>
      Repositories.publicConversation.fetchById(conversationId);

  @override
  Future<List<ExpertInterpretation>> expertsFor(String poemId) async {
    final file = await loadExpertFile(poemId);
    if (file != null) return file.readings;
    return FakeData.expertInterpretations[poemId] ?? const [];
  }

  @override
  Future<List<String>> comparisonTextsFor(String poemId) async =>
      FakeData.comparisonTexts[poemId] ?? const [];
}
```

그리고 화면 네 곳의 기본값을 바꿉니다 (`const FakeReadingSource()` → `const RepositoryReadingSource()`):

```
lib/features/compare/comparison_screen.dart
lib/features/community/community_list_screen.dart
lib/features/community/community_detail_screen.dart
lib/features/profile/profile_screen.dart
```

테스트는 `source:`를 직접 넘기므로 영향받지 않습니다. `FakeReadingSource`는 지우지 말아 주세요 — 테스트와 Firebase 없는 화면 확인에 씁니다.

> C의 저장소는 저장하지 않은 시의 대화를 읽으면 `ConversationsLockedException`을 던집니다. D 화면은 이미 `snapshot.hasError`를 받아 안내를 보여 주므로 스피너가 멈추지 않는 일은 없습니다. 다만 **잠금인지 네트워크 실패인지 구분하지 않습니다.** 예외 타입으로 문구를 나누는 건 어댑터를 끼운 뒤에 하면 됩니다.

### (2) A의 디스패처에 툴 두 개를 잇는다

`lib/agent/tools/agent_tools.dart`가 지금 두 툴을 거부 스텁으로 두고 있습니다. D의 함수는 `lib/compare/compare_tools.dart`에 있고 **아무도 부르지 않습니다.**

```dart
case compareWithExpertsName:
  return ToolResult(compareWithExperts(
    myEvidenceLines: myEvidenceLines,
    myInterpretation: myInterpretation,
    experts: experts));
case getPoemContextName:
  return ToolResult(getPoemContext(poem: poem));
```

`AgentTools`에 `myEvidenceLines` · `myInterpretation` · `experts` 세 필드가 필요합니다. `definitions`에 들어갈 툴 정의 2개는 프롬프트 톤에 맞춰야 하니 A가 써 주시는 게 맞습니다.

**툴 함수는 순수 동기입니다.** `ToolResult run(...)`이 동기라서, D 쪽에서 에셋을 직접 읽으면 `Future`가 되어 디스패처를 전부 async로 뜯어야 합니다. 그래서 필요한 데이터를 인자로 받습니다.

`compare_with_experts` 출력에는 **전문가만 근거로 삼은 행을 넣지 않았습니다.** 기획서 4장이 "전문가는 이 줄도 봤다"류 문장을 금지하므로, 그 재료를 모델에게 미리 계산해 주지 않습니다. `claims`의 `lines`로 모델이 직접 셀 수는 있어서, 그건 프롬프트가 막아야 합니다.

### (3) C의 `saveInterpretation`에서 요약 생성기를 부른다

`saveInterpretation(userId, reading, {summary})`의 `summary`가 지금 비어 있습니다. 주석에 "D의 요약 생성기가 만든 것"이라고 적혀 있는 그 자리입니다.

```dart
final summary = (await const FakeSummaryWriter().write(SummaryRequest(
  poemId: reading.poemId,
  firstWord: reading.firstWord,
  conversation: reading.conversation,
  interpretation: reading.interpretation,
))).text;
```

모델을 부르는 구현체는 A의 PR이 병합된 뒤에 `SummaryWriter`를 구현하는 클래스 하나로 바꿉니다. 요약 때문에 저장이 실패하면 안 되므로 `write`는 예외를 던지지 않습니다 (기획서 9장).

`FakeSummaryWriter`는 **첫 낱말과 AI 질문 수만** 씁니다. 대화 내용을 추측해 옮기지 않습니다 — 남이 읽는 글에 쓰지 않은 말이 들어가면 안 되기 때문이고, 테스트로 막아 두었습니다.

---

## 5. 아직 정하지 않은 것

### 뱃지·공개 대화 규칙이 두 곳에 있습니다

C의 `saveInterpretation` 안에도, D의 `lib/rewards/save_rewards.dart`에도 같은 규칙이 있습니다. **어느 쪽으로 모을지는 토의로 정하기로** 했고, 그때 같은 조건에서 비교되도록 C 쪽에만 있던 `alreadyPublic` 규칙(이미 공개한 시를 다시 저장하면 새로 만들지 않음)을 D 쪽에도 채웠습니다. **지금 두 구현의 규칙은 같습니다.**

| | `lib/rewards/` (D) | `saveInterpretation` 안 (C) |
| --- | --- | --- |
| 뱃지는 시마다 한 번 | ✓ | ✓ |
| 공개 꺼짐 / 해석 빈칸이면 안 만듦 | ✓ | ✓ |
| 이미 공개한 시면 다시 안 만듦 | ✓ | ✓ |
| 단위 테스트 | 13개 | 저장소 테스트에 섞임 |
| 시계를 읽지 않음 | ✓ (`createdAt` 주입) | 구현 안에서 |

하나를 고르면 다른 쪽을 지우면 됩니다. D 쪽을 고르면 C는 직접 구현한 14줄을 2줄로 바꿉니다.

### `AppText` 토큰 9종이 필요합니다 (A)

inline `TextStyle` 47개 중 18개를 걷었고 **29개가 남았습니다.** 값이 같은 토큰이 없어서입니다. 가까운 토큰에 억지로 맞추면 D가 디자인을 바꾸는 셈이고 `theme.dart`는 A 소유라 남겨 두었습니다.

| 쓰임 | 값 | 곳 |
| --- | --- | --- |
| 카드 제목 | 고딕 14 bold text | 2 |
| 구역 제목 | 고딕 15 bold text | 2 |
| 프로필 이름 | 고딕 18 bold text | 1 |
| 누적일수 숫자 | 명조 28 bold accent | 1 |
| 강조 위의 글자 | 고딕 12 bold card | 1 |
| 근거 행 태그 | 고딕 12 bold/w600 confirmed | 2 |
| 첫 낱말 태그 | 고딕 12·14 w600 accent | 2 |
| 작은 인용 | 명조 13 h1.4 / 15 h1.6 / 15 h1.7 text | 3 |
| 흐린 기울임 | 고딕 12 italic textFaint | 1 |

### 공개 대화 문서에 닉네임이 없습니다 (C)

S08이 카드마다 작성자 프로필을 읽어야 합니다. 지금은 uid당 한 번으로 모아 두었고 테스트로 고정했지만(같은 사람 카드 3장 → `profileById` 1회), 문서에 닉네임을 비정규화해 넣는 것이 진짜 해결입니다.

### 전문가 해석과 뱃지 이미지가 부족합니다 (전원)

- `assets/poems/seosi.json`만 있습니다. 진달래꽃·봄은 고양이로다는 같은 형식으로 채우면 파서가 그대로 읽습니다. 없는 동안 S07은 「전문가 해석 준비 중」을 띄웁니다.
- `assets/badges/{poemId}.png`가 비어 있습니다. 없으면 그 시를 닮은 아이콘(별·꽃·고양이)으로 대신 나옵니다.
- `FakeData.expertInterpretations`에 에셋과 겹치는 사본이 남아 있습니다. 포트가 에셋을 먼저 보고 없으면 그 사본으로 되돌아갑니다. `lib/data/fakes`는 C 소유라 지우지 않았습니다.

---

## 6. 제출 전 반드시 — 릴리스 APK에 INTERNET 권한이 없습니다

D 파트와 무관하지만, 합치는 사람이 가장 먼저 알아야 할 것입니다. **실제로 빌드해서 확인했습니다.**

```
$ flutter build apk --release
$ aapt2 dump permissions build/app/outputs/flutter-apk/app-release.apk
package: com.yeobaek.yeobaek
permission:      com.yeobaek.yeobaek.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION
uses-permission: com.yeobaek.yeobaek.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION
```

`android.permission.INTERNET`이 **없습니다.** `android/app/src/debug/`와 `profile/`에만 선언돼 있고 `main/`에는 없기 때문입니다.

**디버그로 시연하면 절대 안 보이고, 제출용 릴리스에서만 터집니다.** 로그인·모델 호출·Firestore가 전부 죽습니다. `android/app/src/main/AndroidManifest.xml`에 한 줄이 필요합니다.

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

같은 파일의 `android:label="yeobaek"`도 「여백」으로 바꿔야 합니다. `android/`는 분업표에 주인이 없어 D가 손대지 않았습니다.

---

## 7. 직접 확인하는 방법

```bash
flutter analyze                 # 0건
flutter test                    # D 브랜치 단독 98개, 전부 합치면 160개
flutter build apk --release     # 성공
```

커밋마다 게이트를 통과하는지도 확인했습니다. 하나씩 체크아웃해 `flutter analyze`를 돌렸고, 읽기 포트를 넣은 커밋 하나에 lint `info` 1건이 섞여 있었습니다(다음 커밋에서 고침). 나머지는 0건입니다.

### 위젯 테스트에서 알아 둘 것 두 가지

`test/support/pump.dart`에 적어 두었지만 여기에도 남깁니다. D 화면을 테스트할 사람이 같은 데 걸립니다.

1. **로딩 스피너는 끝나지 않는 애니메이션입니다.** 스피너가 화면에 남아 있는 동안 `pumpAndSettle`은 시간 초과됩니다. `pumpUntilLoaded`를 쓰세요.
2. **위젯 테스트의 `pump()`는 가짜 비동기 구역에서 돌아 실제 에셋 I/O가 진행되지 않습니다.** 그래서 `rootBundle`을 타는 `expertsFor`를 위젯 테스트에서 쓰면 로딩이 끝나지 않습니다. 화면 테스트는 데이터를 주입하고, 에셋 읽기 자체는 `test/compare/expert_parser_test.dart`가 실제 번들로 검증합니다.
