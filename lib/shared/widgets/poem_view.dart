// 주인: B — 시 본문 위젯. S04 · S05 · S07이 같이 쓴다.
//
// | 표시                              | 쓰이는 곳   |
// | 시 전체, 넉넉한 줄간격 (명조)     | S04         |
// | 행 탭 시 와인색 배경 + 오른쪽 "7명" | S04         |
// | 확인된 근거 행에 초록 실선         | S05 · S07   |
// | 가리키는 중인 행에 회색 점선       | S05         |
// | 작게 (compact)                     | S05         |
//
// 행 번호는 1부터 센다. 연 구분 빈 줄도 번호를 하나 차지한다.
import 'package:flutter/material.dart';

import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../data/models/poem.dart';

class PoemView extends StatelessWidget {
  const PoemView({
    super.key,
    required this.poem,
    this.compact = false,
    this.showLineNumbers = false,
    this.markedLines = const {},
    this.stopCounts = const {},
    this.evidenceLines = const {},
    this.pointingLine,
    this.onLineTap,
  });

  final Poem poem;

  /// 작은 글씨 · 좁은 줄간격 (S05 상단 고정용)
  final bool compact;
  final bool showLineNumbers;

  /// 멈춘 행 — 와인색 배경
  final Set<int> markedLines;

  /// 행 번호 → 그 행에서 멈춘 사람 수. 멈춘 행에만 오른쪽에 표시한다.
  final Map<int, int> stopCounts;

  /// 확인된 근거 행 — 초록 실선
  final Set<int> evidenceLines;

  /// 지금 가리키는 중인 행 — 회색 점선
  final int? pointingLine;

  /// 행을 누르면 그 행 번호(1부터)를 넘긴다
  final ValueChanged<int>? onLineTap;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < poem.lines.length; i++) {
      final lineNo = i + 1;
      final text = poem.lines[i];
      if (text.isEmpty) {
        children.add(SizedBox(height: compact ? 10 : 20));
        continue;
      }
      children.add(
        _PoemLine(
          lineNo: lineNo,
          text: text,
          compact: compact,
          showLineNumber: showLineNumbers,
          isMarked: markedLines.contains(lineNo),
          stopCount: stopCounts[lineNo],
          isEvidence: evidenceLines.contains(lineNo),
          isPointing: pointingLine == lineNo,
          onTap: onLineTap,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

class _PoemLine extends StatelessWidget {
  const _PoemLine({
    required this.lineNo,
    required this.text,
    required this.compact,
    required this.showLineNumber,
    required this.isMarked,
    required this.stopCount,
    required this.isEvidence,
    required this.isPointing,
    required this.onTap,
  });

  final int lineNo;
  final String text;
  final bool compact;
  final bool showLineNumber;
  final bool isMarked;
  final int? stopCount;
  final bool isEvidence;
  final bool isPointing;
  final ValueChanged<int>? onTap;

  TextStyle get _style {
    final base = compact ? AppText.poemLineCompact : AppText.poemLine;
    if (isEvidence) {
      return base.copyWith(
        decoration: TextDecoration.underline,
        decorationColor: AppColors.confirmed,
        decorationStyle: TextDecorationStyle.solid,
        decorationThickness: 2,
      );
    }
    if (isPointing) {
      return base.copyWith(
        decoration: TextDecoration.underline,
        decorationColor: AppColors.textFaint,
        decorationStyle: TextDecorationStyle.dotted,
        decorationThickness: 2,
      );
    }
    return base;
  }

  @override
  Widget build(BuildContext context) {
    final count = stopCount;
    final row = Row(
      children: [
        if (showLineNumber)
          SizedBox(
            width: 26,
            child: Text('$lineNo', style: AppText.lineNumber),
          ),
        Expanded(child: Text(text, style: _style)),
        if (isMarked && count != null)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(AppStrings.stopCount(count), style: AppText.stopCount),
          ),
      ],
    );

    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: compact ? 0 : 2),
      decoration: BoxDecoration(
        color: isMarked ? AppColors.accentBg : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: row,
    );

    final tap = onTap;
    if (tap == null) return content;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => tap(lineNo),
      child: content,
    );
  }
}
