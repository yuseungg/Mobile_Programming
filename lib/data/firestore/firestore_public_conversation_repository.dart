// 주인: C — 진짜 공개 대화 저장소
// Firestore: publicConversations/{conversationId} (+ empathies/{userId})
//
// 열람 잠금(그 시의 해석을 저장한 사람만)은 보안 규칙이 막는다.
// 규칙이 막으면 permission-denied가 오고, 여기서 ConversationsLockedException으로 바꾼다.

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/public_conversation.dart';
import '../repositories/public_conversation_repository.dart';
import 'converters.dart';

class FirestorePublicConversationRepository
    implements PublicConversationRepository {
  FirestorePublicConversationRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _conversations =>
      _db.collection('publicConversations');

  DocumentReference<Map<String, dynamic>> _empathy(
          String conversationId, String userId) =>
      _conversations.doc(conversationId).collection('empathies').doc(userId);

  static bool _isDenied(FirebaseException e) => e.code == 'permission-denied';

  @override
  Future<List<PublicConversation>> fetchForPoem(String poemId) async {
    try {
      final snap = await _conversations
          .where('poemId', isEqualTo: poemId)
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs
          .map((d) => publicConversationFromDoc(d.id, d.data()))
          .toList();
    } on FirebaseException catch (e) {
      if (_isDenied(e)) throw ConversationsLockedException(poemId);
      rethrow;
    }
  }

  @override
  Future<PublicConversation> fetchById(String conversationId) async {
    final DocumentSnapshot<Map<String, dynamic>> snap;
    try {
      snap = await _conversations.doc(conversationId).get();
    } on FirebaseException catch (e) {
      if (_isDenied(e)) throw ConversationsLockedException(_poemIdOf(conversationId));
      rethrow;
    }
    final data = snap.data();
    if (data == null) {
      throw StateError('no public conversation: $conversationId');
    }
    return publicConversationFromDoc(conversationId, data);
  }

  @override
  Future<bool> hasEmpathized(String conversationId, String userId) async {
    try {
      return (await _empathy(conversationId, userId).get()).exists;
    } on FirebaseException catch (e) {
      if (_isDenied(e)) return false; // 잠긴 시
      rethrow;
    }
  }

  @override
  Future<void> setEmpathy(
    String conversationId,
    String userId, {
    required bool hasEmpathized,
  }) async {
    final conversationRef = _conversations.doc(conversationId);
    final empathyRef = _empathy(conversationId, userId);
    try {
      await _db.runTransaction((tx) async {
        final conversation = await tx.get(conversationRef);
        final empathy = await tx.get(empathyRef);
        if (!conversation.exists || empathy.exists == hasEmpathized) return;

        if (hasEmpathized) {
          tx.set(empathyRef, <String, Object>{});
        } else {
          tx.delete(empathyRef);
        }
        tx.update(conversationRef, {
          'empathyCount': FieldValue.increment(hasEmpathized ? 1 : -1),
        });
      });
    } on FirebaseException catch (e) {
      if (_isDenied(e)) throw ConversationsLockedException(_poemIdOf(conversationId));
      rethrow;
    }
  }

  /// 문서를 못 읽으면 poemId를 모른다 — id가 {userId}_{poemId}이므로 뒤쪽을 쓴다.
  /// (Firebase uid에는 밑줄이 없다)
  static String _poemIdOf(String conversationId) =>
      conversationId.substring(conversationId.indexOf('_') + 1);
}
