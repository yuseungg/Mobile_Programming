// 주인: B — 시 본문 위젯 (S04 · S05 · S07 공용)
// B의 part-b 위젯을 이름만 맞춰 옮겼다 (docs/여백-이름대조표.md 5장).
//
// - 행 번호는 1부터. 빈 문자열은 연 구분으로 보고 탭하지 않음
// - 명조체
// - 밑줄: 초록 실선 = 확인된 근거 행, 회색 점선 = 지금 가리키는 중
// - compact: S05 상단 고정용 작은 크기 (멈춘 사람 수 숨김)
import 'package:flutter/material.dart';

import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../data/models/poem.dart';

class PoemView extends StatelessWidget {
  const PoemView({
    super.key,
    required this.poem,
    this.markedLines = const {},
    this.stopCounts = const {},
    this.evidenceLines = const {},
    this.pointingLine,
    this.onLineTap,
    this.compact = false,
    this.showLineNumbers = false,
  });

  final Poem poem;
  final Set<int> markedLines; // 내가 멈춘 행 — 와인색 배경
  final Map<int, int> stopCounts; // 행별 멈춘 사람 수
  final Set<int> evidenceLines; // 확인된 근거 행 — 초록 실선
  final int? pointingLine; // 지금 가리키는 행 — 회색 점선
  final ValueChanged<int>? onLineTap;
  final bool compact;
  final bool showLineNumbers; // S05에서 "6행"을 바로 보이게

  @override
  Widget build(BuildContext context) {
    final fontSize = compact ? 14.0 : 18.0;
    final lines = poem.lines;
    return Container(
      padding: const EdgeInsets.only(left: 8),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: AppColors.border, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < lines.length; i++)
            lines[i].isEmpty
                ? SizedBox(height: fontSize)
                : _line(i + 1, lines[i], fontSize),
        ],
      ),
    );
  }

  Widget _line(int lineNo, String text, double fontSize) {
    final isMarked = markedLines.contains(lineNo);
    final isEvidence = evidenceLines.contains(lineNo);
    final isUnderlined = isEvidence || pointingLine == lineNo;
    final count = stopCounts[lineNo] ?? 0;
    final tap = onLineTap;

    return InkWell(
      onTap: tap == null ? null : () => tap(lineNo),
      child: Container(
        decoration: BoxDecoration(
          color: isMarked ? AppColors.accentBg : null,
          borderRadius: BorderRadius.circular(4),
        ),
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: compact ? 2 : 4),
        child: Row(
          children: [
            if (showLineNumbers)
              SizedBox(
                width: 24,
                child: Text('$lineNo', style: AppText.lineNumber),
              ),
            Expanded(
              child: Text(
                text,
                style: AppText.poemLine.copyWith(
                  fontSize: fontSize,
                  height: 1.8,
                  decoration: isUnderlined ? TextDecoration.underline : null,
                  decorationStyle: isEvidence
                      ? TextDecorationStyle.solid
                      : TextDecorationStyle.dashed,
                  decorationColor:
                      isEvidence ? AppColors.confirmed : AppColors.textFaint,
                  decorationThickness: 2,
                ),
              ),
            ),
            // 멈춘 사람 수는 내가 멈춘 행에만 (누르기 전에 남의 선택을 보여주지 않음)
            if (!compact && isMarked && count > 0)
              Text(
                AppStrings.stopCount(count),
                style: AppText.caption,
              ),
          ],
        ),
      ),
    );
  }
}
