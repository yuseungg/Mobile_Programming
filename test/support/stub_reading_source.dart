// 테스트용 ReadingSource — 필요한 것만 넣고 나머지는 가짜 데이터를 쓴다.
import 'package:yeobaek/data/models/expert_interpretation.dart';
import 'package:yeobaek/data/models/poem.dart';
import 'package:yeobaek/data/models/public_conversation.dart';
import 'package:yeobaek/data/models/reading.dart';
import 'package:yeobaek/data/models/user_profile.dart';
import 'package:yeobaek/ports/fake_reading_source.dart';
import 'package:yeobaek/ports/reading_source.dart';

class StubReadingSource implements ReadingSource {
  StubReadingSource({
    this.readings = const {},
    this.conversations = const [],
    this.experts = const {},
    this.comparisonTexts = const {},
    this.profiles = const {},
    this.todayPoemIdOverride,
  });

  final Map<String, Reading> readings;
  final List<PublicConversation> conversations;
  final Map<String, List<ExpertInterpretation>> experts;
  final Map<String, List<String>> comparisonTexts;
  final Map<String, UserProfile> profiles;
  final String? todayPoemIdOverride;

  final _fallback = const FakeReadingSource();

  /// 포트를 몇 번 불렀는지 — N+1을 테스트로 잡는다
  final calls = <String>[];

  @override
  String get myUserId => _fallback.myUserId;

  @override
  String get todayPoemId => todayPoemIdOverride ?? _fallback.todayPoemId;

  @override
  Future<List<Poem>> poems() => _fallback.poems();

  @override
  Future<Poem> poemById(String poemId) => _fallback.poemById(poemId);

  @override
  Future<Reading?> readingFor(String poemId) async {
    calls.add('readingFor:$poemId');
    return readings[poemId];
  }

  @override
  Future<UserProfile> profileById(String userId) async {
    calls.add('profileById:$userId');
    return profiles[userId] ?? await _fallback.profileById(userId);
  }

  @override
  Future<List<PublicConversation>> conversationsFor(String poemId) async {
    calls.add('conversationsFor:$poemId');
    return conversations.where((c) => c.poemId == poemId).toList();
  }

  @override
  Future<PublicConversation> conversationById(String conversationId) async {
    calls.add('conversationById:$conversationId');
    return conversations.firstWhere(
      (c) => c.conversationId == conversationId,
      orElse: () => conversations.first,
    );
  }

  @override
  Future<List<ExpertInterpretation>> expertsFor(String poemId) async =>
      experts[poemId] ?? const [];

  @override
  Future<List<String>> comparisonTextsFor(String poemId) async =>
      comparisonTexts[poemId] ?? const [];
}
