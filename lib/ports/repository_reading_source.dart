// 주인: D — ReadingSource의 진짜 구현. C의 저장소(Repositories)에서 읽는다.
//
// 가짜 구현(FakeReadingSource)과 같은 인터페이스라 화면은 바뀌지 않는다.
// 바뀌는 것은 화면 생성자의 기본값 한 줄뿐이다.
//
// 어디서 읽는지:
//   내 읽기 · 프로필 · 공개 대화 → C의 저장소 (사람이 만든 데이터)
//   시 본문 · 오늘의 시 · 전문가 해석 → 앱 번들 (콘텐츠. Firestore에 없다)
//   비교 문장 → 아직 가짜. 모델 호출 구현체가 들어오면 lib/writers/로 옮긴다.
//
// 로그인 전에는 내 것을 읽을 수 없다. 그때 빈 사용자 id로 경로를 만들면
// Firestore가 던지므로, 아예 묻지 않고 비어 있는 결과를 돌려준다.

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

  /// 로그인 전에는 빈 문자열. 어떤 uid와도 같지 않으므로 「내 것」 판정이 false가 된다.
  @override
  String get myUserId => Repositories.auth.currentUserId ?? '';

  @override
  String get todayPoemId => FakeData.todayPoemId;

  @override
  Future<List<Poem>> poems() async => FakeData.poems;

  @override
  Future<Poem> poemById(String poemId) async => FakeData.poemById(poemId);

  @override
  Future<Reading?> readingFor(String poemId) async {
    final userId = Repositories.auth.currentUserId;
    if (userId == null) return null; // 아직 로그인 전 = 아직 읽지 않았다
    return Repositories.reading.fetchReading(userId, poemId);
  }

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
}
