// 주인: C — 진짜 읽기 저장소
// Firestore: users/{userId}/readings/{poemId} · lineStops/{poemId}
//            저장할 때는 users/{userId}(뱃지) · publicConversations도 함께 쓴다
//
// 규칙(잠금 · 공개 유지 · 공개 대화 생성 조건)은 가짜 구현과 똑같다.
// 보안 규칙(firestore.rules)도 같은 조건을 서버에서 다시 막는다.

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/reading.dart';
import '../repositories/public_conversation_repository.dart';
import '../repositories/reading_repository.dart';
import 'converters.dart';

class FirestoreReadingRepository implements ReadingRepository {
  FirestoreReadingRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _user(String userId) =>
      _db.collection('users').doc(userId);

  CollectionReference<Map<String, dynamic>> _readings(String userId) =>
      _user(userId).collection('readings');

  DocumentReference<Map<String, dynamic>> _reading(
          String userId, String poemId) =>
      _readings(userId).doc(poemId);

  DocumentReference<Map<String, dynamic>> _lineStops(String poemId) =>
      _db.collection('lineStops').doc(poemId);

  DocumentReference<Map<String, dynamic>> _conversation(String id) =>
      _db.collection('publicConversations').doc(id);

  static Reading? _readingOf(
    String poemId,
    DocumentSnapshot<Map<String, dynamic>> snap,
  ) {
    final data = snap.data();
    return data == null ? null : readingFromDoc(poemId, data);
  }

  /// 대조를 연 뒤에는 해석을 바꿀 수 없다.
  static void _checkLock(Reading? saved, Reading reading) {
    if (saved != null &&
        saved.hasOpenedComparison &&
        saved.interpretation != reading.interpretation) {
      throw InterpretationLockedException(reading.poemId);
    }
  }

  static bool _isAlreadyPublic(Reading? saved) =>
      saved != null && saved.isSaved && saved.isPublic;

  @override
  Future<Reading?> fetchReading(String userId, String poemId) async =>
      _readingOf(poemId, await _reading(userId, poemId).get());

  @override
  Future<List<Reading>> fetchMyReadings(String userId) async {
    final snap = await _readings(userId).get();
    return snap.docs.map((d) => readingFromDoc(d.id, d.data())).toList();
  }

  @override
  Future<void> saveProgress(String userId, Reading reading) {
    final ref = _reading(userId, reading.poemId);
    return _db.runTransaction((tx) async {
      final saved = _readingOf(reading.poemId, await tx.get(ref));
      _checkLock(saved, reading);
      tx.set(
        ref,
        readingToDoc(reading.copyWith(
          isSaved: saved?.isSaved ?? false,
          hasOpenedComparison: saved?.hasOpenedComparison ?? false,
          isPublic: _isAlreadyPublic(saved) || reading.isPublic,
        )),
      );
    });
  }

  @override
  Future<String?> saveInterpretation(
    String userId,
    Reading reading, {
    required String? summary,
  }) {
    final readingRef = _reading(userId, reading.poemId);
    final userRef = _user(userId);
    final conversationId = publicConversationIdOf(userId, reading.poemId);
    final conversationRef = _conversation(conversationId);

    return _db.runTransaction((tx) async {
      // 트랜잭션에서는 읽기를 모두 쓰기보다 먼저 한다
      final before = _readingOf(reading.poemId, await tx.get(readingRef));
      final userSnap = await tx.get(userRef);
      final conversationSnap = await tx.get(conversationRef);
      if (!userSnap.exists) throw StateError('no profile: $userId');

      _checkLock(before, reading);
      final saved = reading.copyWith(
        isSaved: true,
        hasOpenedComparison: before?.hasOpenedComparison ?? false,
        isPublic: _isAlreadyPublic(before) || reading.isPublic,
      );
      final createsConversation = saved.isPublic &&
          !conversationSnap.exists &&
          saved.interpretation.trim().isNotEmpty;
      if (createsConversation && (summary == null || summary.trim().isEmpty)) {
        throw ArgumentError.value(summary, 'summary', '공개 저장에는 요약이 필요함');
      }

      tx.set(readingRef, readingToDoc(saved));

      final badgeIds = List<String>.from(
          userSnap.data()?['badgeIds'] as List? ?? const <String>[]);
      if (!badgeIds.contains(saved.poemId)) {
        tx.update(userRef, {
          'badgeIds': FieldValue.arrayUnion([saved.poemId]),
        });
      }

      if (!createsConversation) return null;
      tx.set(conversationRef, {
        'userId': userId,
        'poemId': saved.poemId,
        'firstWord': saved.firstWord,
        'summary': summary!.trim(),
        'interpretation': saved.interpretation,
        'empathyCount': 0,
        'evidenceLines': saved.evidenceLines,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return conversationId;
    });
  }

  @override
  Future<void> openComparison(String userId, String poemId) {
    final ref = _reading(userId, poemId);
    return _db.runTransaction((tx) async {
      final saved = _readingOf(poemId, await tx.get(ref));
      if (saved == null || !saved.isSaved || saved.hasOpenedComparison) return;
      tx.update(ref, {'hasOpenedComparison': true});
    });
  }

  @override
  Future<void> setMarkedLine(
    String userId,
    String poemId,
    int lineNo, {
    required bool isMarked,
  }) {
    final readingRef = _reading(userId, poemId);
    return _db.runTransaction((tx) async {
      final reading = _readingOf(poemId, await tx.get(readingRef)) ??
          Reading(poemId: poemId);
      if (reading.markedLines.contains(lineNo) == isMarked) return;

      final markedLines = isMarked
          ? ([...reading.markedLines, lineNo]..sort())
          : reading.markedLines.where((n) => n != lineNo).toList();
      tx.set(readingRef, readingToDoc(reading.copyWith(markedLines: markedLines)));
      tx.set(
        _lineStops(poemId),
        {
          'counts': {'$lineNo': FieldValue.increment(isMarked ? 1 : -1)},
        },
        SetOptions(merge: true),
      );
    });
  }

  @override
  Future<Map<int, int>> fetchStopCounts(String poemId) async =>
      stopCountsFromDoc((await _lineStops(poemId).get()).data());

  @override
  Future<void> clearConversations(String userId) async {
    final snap = await _readings(userId).get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'conversation': <Object>[]});
    }
    await batch.commit();
  }
}
