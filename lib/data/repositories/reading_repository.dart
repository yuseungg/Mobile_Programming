// 주인: C — 내 읽기 기록 · 멈춤 집계 (F2 F4)
// Firestore: users/{userId}/readings/{poemId} · lineStops/{poemId}
//            저장할 때는 users/{userId}(뱃지) · publicConversations도 함께 쓴다
// 사용: B(S03 S04 S06), A(S05 대화 이어 쓰기), D(S07 대조 열람)
//
// 행 번호는 모두 1부터.

import '../models/reading.dart';

/// 대조를 연 뒤에 해석을 고치려 할 때 던진다 (F4 "대조를 연 뒤에는 수정 불가").
class InterpretationLockedException implements Exception {
  const InterpretationLockedException(this.poemId);
  final String poemId;

  @override
  String toString() => 'InterpretationLockedException($poemId)';
}

abstract interface class ReadingRepository {
  /// 아직 읽은 적 없는 시면 null.
  Future<Reading?> fetchReading(String userId, String poemId);

  /// S03 "내가 읽은 시".
  Future<List<Reading>> fetchMyReadings(String userId);

  /// 이어 읽기용 중간 저장 (첫 낱말 · 대화 · 근거 행 등). isSaved는 바꾸지 않는다.
  /// 대조를 연 뒤에 해석이 바뀌어 있으면 [InterpretationLockedException].
  Future<void> saveProgress(String userId, Reading reading);

  /// S06 최종 저장 — 유일한 잠금 해제 지점. 아래 셋이 **한 트랜잭션**으로 일어난다.
  ///  1. 읽기의 isSaved를 true로
  ///  2. 그 시의 뱃지가 없으면 지급 (시마다 한 번)
  ///  3. reading.isPublic이고 해석이 비어 있지 않으면 공개 대화를 만든다.
  ///     [summary]는 D의 요약 생성기가 만든 것. 이미 공개한 시를 다시 저장하면 새로 만들지 않는다.
  /// 만든 공개 대화의 conversationId를 돌려준다. 만들지 않았으면 null.
  /// 대조를 연 뒤에 해석이 바뀌어 있으면 [InterpretationLockedException].
  Future<String?> saveInterpretation(
    String userId,
    Reading reading, {
    String summary = '',
  });

  /// S07을 처음 열 때. hasOpenedComparison을 true로 만든다. 저장 전이면 아무 일도 하지 않는다.
  Future<void> openComparison(String userId, String poemId);

  /// S04 멈춘 행 표시를 켜고 끈다. 내 markedLines와 lineStops 집계를 한 번에 바꾼다.
  Future<void> setMarkedLine(
    String userId,
    String poemId,
    int lineNo, {
    required bool isMarked,
  });

  /// 행 번호 → 그 행에서 멈춘 사람 수(stopCount).
  Future<Map<int, int>> fetchStopCounts(String poemId);

  /// S11 기록 지우기. 모든 읽기의 대화(conversation)만 비운다.
  /// 저장한 해석 · 뱃지 · 누적일수 · 공개한 대화는 그대로 둔다.
  Future<void> clearConversations(String userId);
}
