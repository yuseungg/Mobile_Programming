// 주인: A — 한 턴에서 확인된 근거 행과 가리키는 행을 정한다 (기획서 F3 「시 고정 표시」)
// 근거 행(초록 실선): 사용자가 근거로 든 구절 · 행이 verify_quote로 원문에서 확인된 행
// 가리키는 행(회색 점선): AI가 지금 짚고 있는 행. 한 번에 한 줄
import '../data/models/poem.dart';
import 'tools/poem_text.dart';
import 'tools/search_poem_lines.dart';
import 'tools/verify_quote.dart';

class LineMarks {
  const LineMarks({this.evidenceLines = const [], this.pointingLine});

  final List<int> evidenceLines; // 1부터, 작은 수부터
  final int? pointingLine;
}

LineMarks resolveLineMarks({
  required Poem poem,
  required String userText, // 이번 턴의 사용자 말. 첫 질문 · 힌트처럼 없으면 ''
  required List<QuoteCheck> quoteChecks,
  required List<List<LineMatch>> searches,
  required String replyText,
}) {
  final userWords = collapseSpaces(userText);
  final userLineNos = lineNosMentioned(userText, poem);

  final evidence = <int>{};
  final pointedByAssistant = <int>[];
  for (final check in quoteChecks) {
    if (!check.isFound) continue;
    // 사용자가 그 구절을 직접 썼거나 "N행"으로 짚었으면 사용자의 근거, 아니면 AI가 짚은 것
    final isUserEvidence = userWords.contains(check.quote) ||
        check.lineNos.any(userLineNos.contains);
    if (isUserEvidence) {
      evidence.addAll(check.lineNos);
    } else {
      pointedByAssistant.addAll(check.lineNos);
    }
  }

  // 가리키는 행: AI 응답이 "N행"으로 짚은 첫 행 → AI가 확인한 구절의 행 → 검색 결과가 한 줄뿐이면 그 행
  final singleSearchHits = [
    for (final matches in searches)
      if (matches.length == 1) matches.first.lineNo,
  ];
  final pointingLine = lineNosMentioned(replyText, poem).firstOrNull ??
      pointedByAssistant.firstOrNull ??
      singleSearchHits.firstOrNull;

  return LineMarks(
    evidenceLines: evidence.toList()..sort(),
    pointingLine: pointingLine,
  );
}
