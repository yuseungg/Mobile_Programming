// 주인: C — 모델 ↔ Firestore 문서 변환
//
// 필드 이름은 docs/여백-네이밍규칙.md 5장과 Dart 모델 필드 이름 그대로.
// 날짜는 Firestore Timestamp로 저장한다. 서버 시간이 아직 안 찍힌 문서
// (serverTimestamp 직후 로컬 캐시)는 null로 오므로 그때는 지금 시각으로 읽는다.

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat_message.dart';
import '../models/public_conversation.dart';
import '../models/reading.dart';
import '../models/user_profile.dart';

DateTime _dateOf(Object? value) =>
    value is Timestamp ? value.toDate() : DateTime.now();

List<int> _intsOf(Object? value) =>
    value is List ? value.whereType<num>().map((n) => n.toInt()).toList() : [];

List<String> _stringsOf(Object? value) =>
    value is List ? value.whereType<String>().toList() : [];

// ── users/{userId} ─────────────────────────────────────

UserProfile userProfileFromDoc(String userId, Map<String, dynamic> data) =>
    UserProfile(
      userId: userId,
      nickname: data['nickname'] as String? ?? '',
      totalReadingDays: (data['totalReadingDays'] as num?)?.toInt() ?? 0,
      lastCountedDate: _dateOf(data['lastCountedDate']),
      badgeIds: _stringsOf(data['badgeIds']),
    );

/// 가입 직후의 새 프로필. lastCountedDate는 1970년 — 첫 읽기에서 바로 +1 된다.
Map<String, dynamic> newUserProfileDoc(String nickname) => {
      'nickname': nickname,
      'totalReadingDays': 0,
      'lastCountedDate': Timestamp.fromMillisecondsSinceEpoch(0),
      'badgeIds': <String>[],
    };

// ── users/{userId}/readings/{poemId} ───────────────────

Map<String, dynamic> chatMessageToMap(ChatMessage message) => {
      'role': message.role.name,
      'text': message.text,
    };

ChatMessage chatMessageFromMap(Map<String, dynamic> map) => ChatMessage(
      role: map['role'] == ChatRole.user.name
          ? ChatRole.user
          : ChatRole.assistant,
      text: map['text'] as String? ?? '',
    );

Map<String, dynamic> readingToDoc(Reading reading) => {
      'firstWord': reading.firstWord,
      'markedLines': reading.markedLines,
      'conversation': reading.conversation.map(chatMessageToMap).toList(),
      'evidenceLines': reading.evidenceLines,
      'interpretation': reading.interpretation,
      'isSaved': reading.isSaved,
      'hasOpenedComparison': reading.hasOpenedComparison,
      'isPublic': reading.isPublic,
      // 고르지 않았으면 키 자체를 넣지 않는다 — 규칙이 있을 때만 검사하도록.
      if (reading.impressiveLine != null)
        'impressiveLine': reading.impressiveLine,
    };

Reading readingFromDoc(String poemId, Map<String, dynamic> data) => Reading(
      poemId: poemId,
      firstWord: data['firstWord'] as String? ?? '',
      markedLines: _intsOf(data['markedLines']),
      conversation: (data['conversation'] as List? ?? const [])
          .whereType<Map>()
          .map((m) => chatMessageFromMap(Map<String, dynamic>.from(m)))
          .toList(),
      evidenceLines: _intsOf(data['evidenceLines']),
      interpretation: data['interpretation'] as String? ?? '',
      isSaved: data['isSaved'] as bool? ?? false,
      hasOpenedComparison: data['hasOpenedComparison'] as bool? ?? false,
      isPublic: data['isPublic'] as bool? ?? false,
      impressiveLine: (data['impressiveLine'] as num?)?.toInt(),
    );

// ── publicConversations/{conversationId} ───────────────

PublicConversation publicConversationFromDoc(
  String conversationId,
  Map<String, dynamic> data,
) =>
    PublicConversation(
      conversationId: conversationId,
      userId: data['userId'] as String? ?? '',
      poemId: data['poemId'] as String? ?? '',
      firstWord: data['firstWord'] as String? ?? '',
      summary: data['summary'] as String? ?? '',
      interpretation: data['interpretation'] as String? ?? '',
      empathyCount: (data['empathyCount'] as num?)?.toInt() ?? 0,
      evidenceLines: _intsOf(data['evidenceLines']),
      createdAt: _dateOf(data['createdAt']),
    );

// ── lineStops/{poemId} ─────────────────────────────────

/// `counts: {"1": 3, "6": 7}` → `{1: 3, 6: 7}`. 0 이하는 뺀다.
Map<int, int> stopCountsFromDoc(Map<String, dynamic>? data) {
  final counts = data?['counts'];
  if (counts is! Map) return {};
  final result = <int, int>{};
  counts.forEach((key, value) {
    final lineNo = int.tryParse('$key');
    final count = value is num ? value.toInt() : 0;
    if (lineNo != null && count > 0) result[lineNo] = count;
  });
  return result;
}
