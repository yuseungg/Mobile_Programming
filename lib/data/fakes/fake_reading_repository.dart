// 주인: C — 가짜 읽기 저장소.

import '../models/public_conversation.dart';
import '../models/reading.dart';
import '../repositories/reading_repository.dart';
import 'fake_store.dart';

class FakeReadingRepository implements ReadingRepository {
  FakeReadingRepository(this._store);

  final FakeStore _store;

  Map<String, Reading> _of(String userId) => _store.readingsOf(userId);

  /// 대조를 연 뒤에는 해석을 바꿀 수 없다.
  void _checkLock(String userId, Reading reading) {
    final saved = _of(userId)[reading.poemId];
    if (saved != null &&
        saved.hasOpenedComparison &&
        saved.interpretation != reading.interpretation) {
      throw InterpretationLockedException(reading.poemId);
    }
  }

  @override
  Future<Reading?> fetchReading(String userId, String poemId) async =>
      _of(userId)[poemId];

  @override
  Future<List<Reading>> fetchMyReadings(String userId) async =>
      _of(userId).values.toList();

  @override
  Future<void> saveProgress(String userId, Reading reading) async {
    _checkLock(userId, reading);
    final saved = _of(userId)[reading.poemId];
    _of(userId)[reading.poemId] = reading.copyWith(
      isSaved: saved?.isSaved ?? false,
      hasOpenedComparison: saved?.hasOpenedComparison ?? false,
    );
  }

  @override
  Future<String?> saveInterpretation(
    String userId,
    Reading reading, {
    required String summary,
  }) async {
    _checkLock(userId, reading);
    final before = _of(userId)[reading.poemId];
    final profile = _store.profiles[userId];
    if (profile == null) throw StateError('no profile: $userId');

    // 여기서부터 Firestore에서는 한 트랜잭션
    final alreadyPublic = before != null && before.isSaved && before.isPublic;
    final saved = reading.copyWith(
      isSaved: true,
      hasOpenedComparison: before?.hasOpenedComparison ?? false,
      isPublic: alreadyPublic || reading.isPublic, // 공개는 되돌릴 수 없다
    );
    _of(userId)[reading.poemId] = saved;

    if (!profile.badgeIds.contains(reading.poemId)) {
      _store.putProfile(
        profile.copyWith(badgeIds: [...profile.badgeIds, reading.poemId]),
      );
    }

    if (!saved.isPublic ||
        alreadyPublic ||
        saved.interpretation.trim().isEmpty) {
      return null;
    }
    final conversationId = _store.newId('post');
    _store.conversations[conversationId] = PublicConversation(
      conversationId: conversationId,
      userId: userId,
      poemId: saved.poemId,
      firstWord: saved.firstWord,
      summary: summary,
      interpretation: saved.interpretation,
      empathyCount: 0,
      evidenceLines: List<int>.unmodifiable(saved.evidenceLines),
      createdAt: _store.now(),
    );
    return conversationId;
  }

  @override
  Future<void> openComparison(String userId, String poemId) async {
    final saved = _of(userId)[poemId];
    if (saved == null || !saved.isSaved) return;
    _of(userId)[poemId] = saved.copyWith(hasOpenedComparison: true);
  }

  @override
  Future<void> setMarkedLine(
    String userId,
    String poemId,
    int lineNo, {
    required bool isMarked,
  }) async {
    final reading = _of(userId)[poemId] ?? Reading(poemId: poemId);
    final wasMarked = reading.markedLines.contains(lineNo);
    if (wasMarked == isMarked) return;

    final markedLines = isMarked
        ? ([...reading.markedLines, lineNo]..sort())
        : reading.markedLines.where((n) => n != lineNo).toList();
    _of(userId)[poemId] = reading.copyWith(markedLines: markedLines);

    final counts = _store.stopCounts.putIfAbsent(poemId, () => {});
    final next = (counts[lineNo] ?? 0) + (isMarked ? 1 : -1);
    if (next > 0) {
      counts[lineNo] = next;
    } else {
      counts.remove(lineNo);
    }
  }

  @override
  Future<Map<int, int>> fetchStopCounts(String poemId) async =>
      Map<int, int>.of(_store.stopCounts[poemId] ?? const {});

  @override
  Future<void> clearConversations(String userId) async {
    final readings = _of(userId);
    for (final poemId in readings.keys.toList()) {
      readings[poemId] = readings[poemId]!.copyWith(conversation: const []);
    }
  }
}
