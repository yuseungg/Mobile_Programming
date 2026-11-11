// 주인: C — 공개 대화 · 공감 (F7 · S08 S09)
// Firestore: publicConversations/{conversationId} (+ empathies/{userId})
// 사용: D
//
// 열람 조건(그 시의 해석을 저장한 사용자만)은 보안 규칙이 막는다.
// 저장하지 않은 시를 읽으려 하면 [ConversationsLockedException].
// 공개 대화를 만드는 함수는 여기 없다 — ReadingRepository.saveInterpretation이 만든다.

import '../models/public_conversation.dart';

class ConversationsLockedException implements Exception {
  const ConversationsLockedException(this.poemId);
  final String poemId;

  @override
  String toString() => 'ConversationsLockedException($poemId)';
}

abstract interface class PublicConversationRepository {
  /// 그 시의 공개 대화. 최신순 (공감 수로 정렬하지 않는다).
  Future<List<PublicConversation>> fetchForPoem(String poemId);

  Future<PublicConversation> fetchById(String conversationId);

  /// 잠긴 시(해석을 저장하지 않은 시)의 대화면 false.
  Future<bool> hasEmpathized(String conversationId, String userId);

  /// 공감 켜기/끄기. empathies 문서와 empathyCount를 한 번에 바꾼다.
  /// 잠긴 시의 대화면 [ConversationsLockedException] (보안 규칙도 쓰기를 막는다).
  Future<void> setEmpathy(
    String conversationId,
    String userId, {
    required bool hasEmpathized,
  });
}
