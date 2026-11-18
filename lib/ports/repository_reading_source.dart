// 주인: D — ReadingSource의 진짜 구현. C의 저장소(Repositories)에서 읽는다.
//
// 가짜 구현(FakeReadingSource)과 같은 인터페이스라 화면은 바뀌지 않는다.
// 바뀌는 것은 화면 생성자의 기본값 한 줄뿐이다.
//
// 어디서 읽는지:
//   내 읽기 · 프로필 · 공개 대화 → C의 저장소 (사람이 만든 데이터)
//   시 본문 · 오늘의 시 · 전문가 해석 → 앱 번들 (콘텐츠. Firestore에 없다)
//   비교 문장 → 미리 쓴 문장만 여기서 읽는다 (폴백의 재료).
//                모델이 쓰는 쪽은 lib/writers/openrouter_comparison_writer.dart.
//
// 화면은 로그인 뒤에만 열리므로 내 id는 Repositories.userId에서 꺼낸다 (로그인 분기 ④).

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
  String get myUserId => Repositories.userId;

  @override
  String get todayPoemId => FakeData.todayPoemId;

  @override
  Future<List<Poem>> poems() async => FakeData.poems;

  @override
  Future<Poem> poemById(String poemId) async => FakeData.poemById(poemId);

  @override
  Future<Reading?> readingFor(String poemId) =>
      Repositories.reading.fetchReading(myUserId, poemId);

  @override
  Future<List<Reading>> myReadings() =>
      Repositories.reading.fetchMyReadings(myUserId);

  @override
  Future<UserProfile> profileById(String userId) =>
      Repositories.user.fetchProfile(userId);

  @override
  Future<List<PublicConversation>> conversationsFor(String poemId) =>
      Repositories.publicConversation.fetchForPoem(poemId);

  @override
  Future<PublicConversation> conversationById(String conversationId) =>
      Repositories.publicConversation.fetchById(conversationId);

  /// 에셋을 먼저 보고, 없으면 가짜 데이터로 되돌아간다 (가짜 구현과 같은 규칙).
  /// 시를 에셋으로 옮기는 중이라 두 곳이 잠시 공존한다.
  @override
  Future<List<ExpertInterpretation>> expertsFor(String poemId) async {
    final file = await loadExpertFile(poemId);
    if (file != null) return file.readings;
    return FakeData.expertInterpretations[poemId] ?? const [];
  }

  @override
  Future<List<String>> comparisonTextsFor(String poemId) async =>
      FakeData.comparisonTexts[poemId] ?? const [];

  /// 대조 열람을 저장소에 알린다. 대조는 이 호출이 실패해도 보여야 하므로
  /// 예외를 먹는다 (잠금이 안 걸리는 것이 화면이 안 열리는 것보다 가볍다).
  @override
  Future<void> markComparisonOpened(String poemId) async {
    try {
      await Repositories.reading.openComparison(myUserId, poemId);
    } catch (_) {
      // 저장 전이거나 권한이 없으면 저장소가 막는다 — 대조는 그대로 보여 준다
    }
  }

  @override
  Future<bool> hasEmpathized(String conversationId) =>
      Repositories.publicConversation.hasEmpathized(conversationId, myUserId);

  /// 예외를 먹지 않는다 — 포트 설명대로 화면이 눌린 상태를 되돌려야 한다.
  /// 잠긴 시의 대화면 저장소가 ConversationsLockedException을 던진다.
  @override
  Future<void> setEmpathy(
    String conversationId, {
    required bool hasEmpathized,
  }) =>
      Repositories.publicConversation.setEmpathy(
        conversationId,
        myUserId,
        hasEmpathized: hasEmpathized,
      );
}
