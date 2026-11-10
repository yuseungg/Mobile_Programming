// 주인: C — 가짜 공개 대화 저장소.
//
// 보안 규칙과 똑같이, 지금 로그인한 사람이 그 시의 해석을 저장하지 않았으면
// 목록 · 상세를 읽을 때 ConversationsLockedException을 던진다.
// 공개 대화는 여기서 만들지 않는다 — ReadingRepository.saveInterpretation이 만든다.

import '../models/public_conversation.dart';
import '../repositories/auth_repository.dart';
import '../repositories/public_conversation_repository.dart';
import 'fake_store.dart';

class FakePublicConversationRepository implements PublicConversationRepository {
  FakePublicConversationRepository(this._store, this._auth);

  final FakeStore _store;
  final AuthRepository _auth;

  void _checkUnlocked(String poemId) {
    final userId = _auth.currentUserId;
    final reading = userId == null ? null : _store.readingsOf(userId)[poemId];
    if (reading == null || !reading.isSaved) {
      throw ConversationsLockedException(poemId);
    }
  }

  @override
  Future<List<PublicConversation>> fetchForPoem(String poemId) async {
    _checkUnlocked(poemId);
    return _store.conversations.values
        .where((c) => c.poemId == poemId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<PublicConversation> fetchById(String conversationId) async {
    final conversation = _store.conversations[conversationId];
    if (conversation == null) {
      throw StateError('no public conversation: $conversationId');
    }
    _checkUnlocked(conversation.poemId);
    return conversation;
  }

  @override
  Future<bool> hasEmpathized(String conversationId, String userId) async =>
      _store.empathies[conversationId]?.contains(userId) ?? false;

  @override
  Future<void> setEmpathy(
    String conversationId,
    String userId, {
    required bool hasEmpathized,
  }) async {
    final conversation = _store.conversations[conversationId];
    if (conversation == null) return;
    final users = _store.empathies.putIfAbsent(conversationId, () => {});
    final changed = hasEmpathized ? users.add(userId) : users.remove(userId);
    if (!changed) return;
    _store.conversations[conversationId] = conversation.copyWith(
      empathyCount: conversation.empathyCount + (hasEmpathized ? 1 : -1),
    );
  }
}
