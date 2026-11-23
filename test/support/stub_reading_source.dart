// 테스트용 ReadingSource — 필요한 것만 넣고 나머지는 가짜 데이터를 쓴다.
import 'dart:async';

import 'package:yeobaek/data/models/expert_interpretation.dart';
import 'package:yeobaek/data/models/poem.dart';
import 'package:yeobaek/data/models/public_conversation.dart';
import 'package:yeobaek/data/models/reading.dart';
import 'package:yeobaek/data/models/user_profile.dart';
import 'package:yeobaek/data/repositories/public_conversation_repository.dart';
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
    this.throwOnRead = false,
    this.empathized = const {},
    this.throwOnSetEmpathy = false,
  });

  final Map<String, Reading> readings;
  final List<PublicConversation> conversations;
  final Map<String, List<ExpertInterpretation>> experts;
  final Map<String, List<String>> comparisonTexts;
  final Map<String, UserProfile> profiles;
  final String? todayPoemIdOverride;

  /// 읽을 때 예외를 던진다. C의 저장소는 저장하지 않은 시의 대화를 읽으면
  /// ConversationsLockedException을 던지므로, 그 경로를 흉내 낸다.
  /// final이 아니다 — 화면이 떠 있는 동안 읽기가 끊기는 상황을 만든다.
  bool throwOnRead;

  final _fallback = const FakeReadingSource();

  /// 포트를 몇 번 불렀는지 — N+1을 테스트로 잡는다
  final calls = <String>[];

  @override
  String get myUserId => _fallback.myUserId;

  @override
  Future<void> markComparisonOpened(String poemId) async {
    calls.add('markComparisonOpened:$poemId');
  }

  @override
  String get todayPoemId => todayPoemIdOverride ?? _fallback.todayPoemId;

  @override
  Future<List<Poem>> poems() => _fallback.poems();

  @override
  Future<Poem> poemById(String poemId) => _fallback.poemById(poemId);

  @override
  Future<Reading?> readingFor(String poemId) async {
    if (throwOnRead) throw StateError('읽을 수 없다');
    calls.add('readingFor:$poemId');
    return readings[poemId];
  }

  @override
  Future<List<Reading>> myReadings() async {
    if (throwOnRead) throw StateError('읽을 수 없다');
    calls.add('myReadings');
    return readings.values.toList();
  }

  @override
  Future<UserProfile> profileById(String userId) async {
    if (throwOnRead) throw StateError('읽을 수 없다');
    calls.add('profileById:$userId');
    return profiles[userId] ?? await _fallback.profileById(userId);
  }

  /// 테스트가 프로필 갱신을 흘려보낼 통로. [pushProfile]로 밀어 넣는다.
  final _profileChanges = StreamController<UserProfile>.broadcast();

  void pushProfile(UserProfile profile) => _profileChanges.add(profile);

  @override
  Stream<UserProfile> watchProfile(String userId) {
    calls.add('watchProfile:$userId');
    return _profileChanges.stream.where((p) => p.userId == userId);
  }

  /// 저장소 쪽에서 대화가 바뀌는 것을 흉내 내려면 고칠 수 있어야 한다.
  /// [conversations]는 const로 넘어오므로 복사해 둔다.
  late final List<PublicConversation> _conversations = [...conversations];

  /// 저장된 대화 하나를 갈아 끼운다 (공감 수가 바뀐 상황).
  void replaceConversation(PublicConversation updated) {
    final at = _conversations.indexWhere(
      (c) => c.conversationId == updated.conversationId,
    );
    if (at < 0) return;
    _conversations[at] = updated;
  }

  @override
  Future<List<PublicConversation>> conversationsFor(String poemId) async {
    if (throwOnRead) throw StateError('읽을 수 없다');
    calls.add('conversationsFor:$poemId');
    return _conversations.where((c) => c.poemId == poemId).toList();
  }

  @override
  Future<PublicConversation> conversationById(String conversationId) async {
    if (throwOnRead) throw StateError('읽을 수 없다');
    calls.add('conversationById:$conversationId');
    return _conversations.firstWhere(
      (c) => c.conversationId == conversationId,
      orElse: () => _conversations.first,
    );
  }

  @override
  Future<List<ExpertInterpretation>> expertsFor(String poemId) async =>
      experts[poemId] ?? const [];

  @override
  Future<List<String>> comparisonTextsFor(String poemId) async =>
      comparisonTexts[poemId] ?? const [];

  /// 처음부터 공감해 둔 대화 id
  final Set<String> empathized;

  /// 공감 쓰기가 실패하는 경우 — 잠긴 시의 대화나 네트워크 문제.
  /// C의 저장소는 ConversationsLockedException을 던진다.
  final bool throwOnSetEmpathy;

  late final _empathized = {...empathized};

  @override
  Future<bool> hasEmpathized(String conversationId) async {
    calls.add('hasEmpathized:$conversationId');
    return _empathized.contains(conversationId);
  }

  @override
  Future<void> setEmpathy(
    String conversationId, {
    required bool hasEmpathized,
  }) async {
    calls.add('setEmpathy:$conversationId:$hasEmpathized');
    if (throwOnSetEmpathy) throw const ConversationsLockedException('seosi');
    if (hasEmpathized) {
      _empathized.add(conversationId);
    } else {
      _empathized.remove(conversationId);
    }
  }
}
