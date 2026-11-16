// 주인: C · 용어: docs/여백-네이밍규칙.md 2장 「읽기 · 대화」
// Reading = 시 한 편에 대한 내 읽기 기록 전체.
// interpretation(해석 문장)은 그 안의 필드 하나다.

import 'chat_message.dart';

class Reading {
  const Reading({
    required this.poemId,
    this.firstWord = '',
    this.markedLines = const [],
    this.conversation = const [],
    this.evidenceLines = const [],
    this.interpretation = '',
    this.isSaved = false,
    this.hasOpenedComparison = false,
    this.isPublic = false,
    int? impressiveLine,
  }) : _impressiveLine = impressiveLine;

  final String poemId;
  final String firstWord; // 첫 낱말
  final List<int> markedLines; // 멈춘 행 (1부터)
  final List<ChatMessage> conversation; // 대화
  final List<int> evidenceLines; // 대화에서 확인된 근거 행 (1부터)
  final String interpretation; // 사용자가 쓴 해석
  final bool isSaved; // 저장했는가 — 유일한 잠금 해제 지점
  final bool hasOpenedComparison; // true면 해석 수정 불가
  final bool isPublic; // 기본 꺼짐

  final int? _impressiveLine;

  /// S06 마지막 질문에서 고른 「가장 인상깊은 행」 (1부터). 고르지 않았으면 null.
  /// 반드시 [markedLines] 안의 행이다 — 선택지가 멈춘 행이기 때문이다.
  /// 같은 시를 다시 읽으면 덮어쓴다 (Reading은 시마다 하나다).
  ///
  /// 고른 뒤에 S04에서 그 행의 멈춤을 해제하면 null이 된다.
  /// 저장소는 문서를 통째로 다시 쓰므로(readingToDoc) 이때 Firestore의 값도 지워진다 —
  /// 보안 규칙의 `impressiveLine in markedLines`에 막히지 않게, 쓰는 길 전부를 여기서 막는다.
  /// 해제한 행을 다시 멈춰도 되살아나지 않는다 (가짜 · 진짜 저장소가 같게).
  int? get impressiveLine =>
      markedLines.contains(_impressiveLine) ? _impressiveLine : null;

  Reading copyWith({
    String? firstWord,
    List<int>? markedLines,
    List<ChatMessage>? conversation,
    List<int>? evidenceLines,
    String? interpretation,
    bool? isSaved,
    bool? hasOpenedComparison,
    bool? isPublic,
    int? impressiveLine,
    bool clearImpressiveLine = false, // true면 고른 행을 지운다 (S06에서 고르지 않음)
  }) =>
      Reading(
        poemId: poemId,
        firstWord: firstWord ?? this.firstWord,
        markedLines: markedLines ?? this.markedLines,
        conversation: conversation ?? this.conversation,
        evidenceLines: evidenceLines ?? this.evidenceLines,
        interpretation: interpretation ?? this.interpretation,
        isSaved: isSaved ?? this.isSaved,
        hasOpenedComparison: hasOpenedComparison ?? this.hasOpenedComparison,
        isPublic: isPublic ?? this.isPublic,
        impressiveLine: clearImpressiveLine
            ? null
            : impressiveLine ?? this.impressiveLine,
      );
}
