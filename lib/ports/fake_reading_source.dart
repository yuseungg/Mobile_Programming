// 주인: D — ReadingSource의 개발용 구현. 1단계 시연이 이것으로 돈다.
//
// 가짜 데이터 자체는 C 소유(lib/data/fakes)라 손대지 않고 그대로 읽는다.
// 전문가 해석은 에셋(assets/poems/*.json)을 먼저 보고, 없으면 가짜 데이터로
// 되돌아간다 — 시를 에셋으로 옮기는 중이라 두 곳이 잠시 공존한다.

import '../compare/expert_parser.dart';
import '../data/fakes/fake_data.dart';
import '../data/models/expert_interpretation.dart';
import '../data/models/poem.dart';
import '../data/models/public_conversation.dart';
import '../data/models/reading.dart';
import '../data/models/user_profile.dart';
import 'reading_source.dart';

class FakeReadingSource implements ReadingSource {
  const FakeReadingSource();

  @override
  String get myUserId => FakeData.myUserId;

  @override
  String get todayPoemId => FakeData.todayPoemId;

  @override
  Future<List<Poem>> poems() async => FakeData.poems;

  @override
  Future<Poem> poemById(String poemId) async => FakeData.poemById(poemId);

  @override
  Future<Reading?> readingFor(String poemId) async =>
      FakeData.readingFor(poemId);

  @override
  Future<List<Reading>> myReadings() async => [
        for (final poem in FakeData.poems) ?FakeData.readingFor(poem.poemId),
      ];

  @override
  Future<UserProfile> profileById(String userId) async =>
      FakeData.profileById(userId);

  @override
  Future<List<PublicConversation>> conversationsFor(String poemId) async =>
      FakeData.conversationsFor(poemId);

  @override
  Future<PublicConversation> conversationById(String conversationId) async =>
      FakeData.conversationById(conversationId);

  @override
  Future<List<ExpertInterpretation>> expertsFor(String poemId) async {
    final file = await loadExpertFile(poemId);
    if (file != null) return file.readings;
    return FakeData.expertInterpretations[poemId] ?? const [];
  }

  @override
  Future<List<String>> comparisonTextsFor(String poemId) async =>
      FakeData.comparisonTexts[poemId] ?? const [];

  /// FakeData는 const라 바꿀 수 없다 — 1단계에서는 잠금이 걸리지 않는다.
  @override
  Future<void> markComparisonOpened(String poemId) async {}
}
