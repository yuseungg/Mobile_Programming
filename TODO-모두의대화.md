# TODO — 모두의 대화(S08 · S09) 2가지

> 강민(A) 개인 메모. **PR 올리기 전에 이 파일 지우기.**
> 기준: develop `288f18d` (#56까지). 팀 합의 완료 · 담당 강민.
> 다른 세션에서 시작: `git fetch origin feat/community-summary-transcript && git checkout feat/community-summary-transcript`

---

## 1. 대화 요약을 한/영 두 벌로 저장 → KR / EN에 맞춰 보여 주기

**지금 문제** — 요약(S09 「2. 대화 과정」)은 저장할 때 **그때 언어로 한 번만** 만들어져 고정된다. 언어를 바꿔도 그대로.

- [x] **저장** — S06에서 요약을 한국어 · 영어 두 벌 만든다
  - `lib/features/save/save_screen.dart:127-137` (`summaryWriter ?? await createSummaryWriter()` → `saveInterpretation(..., summary:)`)
  - 재시도: `lib/features/save/pending_saves.dart:161`
  - 보관도 두 벌로: `pending_saves.dart` 78 · 90행(보관) · 147행(꺼냄). 예전 버전이 `summary` 하나로 보관한 것은 두 언어에 같이 씀
  - 지금도 저장이 1분 넘게 걸림 → 두 벌을 **동시에**(`Future.wait`) 만들거나, 모델 한 번에 두 벌(JSON)로 받기
  - 요약 지시문 · 검사는 `isEnglish`(전역)를 봄 → 언어를 인자로 받게 바꿔야 두 벌을 따로 만들 수 있음
    (`lib/writers/summary_prompt.dart` · `summary_guard.dart` · `fake_summary_writer.dart` · `AppStrings.communitySummaryFallback`)
- [x] **데이터** — `PublicConversation.summary` → `summaryKo` · `summaryEn`
  - 모델: `lib/data/models/public_conversation.dart`
  - 저장소: `saveInterpretation` — `lib/data/repositories/reading_repository.dart:46`, `lib/data/firestore/firestore_reading_repository.dart:85`, `lib/data/fakes/fake_reading_repository.dart:47`
  - 보안 규칙: `firestore.rules:216` 허용 필드 `hasOnly([...])` + `summary is string` · `size() > 0` 검사 (`firestore_test/`도)
  - 네이밍규칙 2장 · 5장(Firestore 필드 = Dart 필드 이름)에 줄 추가
- [x] **화면** — `isEnglish`로 골라서 보여 주기
  - S09: `lib/features/community/community_detail_screen.dart:92`(요약 비었을 때 만드는 곳) · `:297`(보여 주는 곳)
  - S08 카드: `lib/features/community/community_list_screen.dart:354`
- 예전에 올라간 데이터는 시연 전에 다 지우므로 따로 처리 안 함

## 2. S09 「3. 최종 해석」 → 대화 전체 기록 (AI 질문 + 사용자 답, 처음부터 끝까지)

**지금** — 그 자리에 최종 해석 한 문단만 (`community_detail_screen.dart:333`).
공개 대화 문서에는 대화가 **없다** — 대화는 개인 기록 `users/{uid}/readings/{poemId}.conversation`에만 있음.

- [x] **데이터** — 공개 저장할 때 대화를 공개 문서로 복사
  - `PublicConversation`에 대화 필드 추가 (이름: 네이밍규칙 2장 「대화 = `conversation`」)
  - `saveInterpretation`에서 공개 문서 만들 때 같이 넣기 (fake · firestore 둘 다)
  - `firestore.rules:216` 허용 필드 + 타입 검사 추가
- [x] **화면** — `community_detail_screen.dart:333` 구역을 대화 기록으로
  - `ChatBubble`(`lib/shared/widgets/chat_bubble.dart`) 다시 쓰면 S05와 같은 모양
  - 근거 행 · 첫 낱말 구역은 그대로
- [x] **문구** (`lib/app/strings.dart`, 한/영 둘 다)
  - `communityDetailInterpretation`(:335) · `communityDetailInterpretationCaption`(:337) → 「대화 기록」 쪽으로
  - `savePublicCaption`(:209) — 지금 「AI가 의미 있는 내용만 뽑아 올린다」 → **대화 전체가 공개된다**로 (사용자가 동의하는 범위가 바뀜)
- **S11 「대화 기록 지우기」** — 그대로 둠. 지금도 개인 대화만 비우고 공개 대화는 남긴다
  (`clearConversations`, `firestore_reading_repository.dart:182`). 안내 문구 「공개한 대화는 그대로 남아요」와도 맞음

---

## 끝나면
- `flutter analyze` 0건 · `flutter test` 통과 (CI는 Flutter 3.47.9)
- 테스트: 한/영 요약 둘 다 저장되는지, EN · KR에서 각각 맞는 요약이 보이는지, S09에 대화 전체가 나오는지
- 보안 규칙 테스트(`firestore_test/`) 새 필드로 통과
- 리뷰어: C(모델 · 저장소 · 보안 규칙), D(S08 · S09 · 요약), B(S06)
- **이 파일 지우고** PR (`develop` 대상)
