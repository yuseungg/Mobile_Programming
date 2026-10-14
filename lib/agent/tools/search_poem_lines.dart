// 주인: A — 툴 search_poem_lines (기획서 6장)
// 시 안에서 낱말을 찾아 그 낱말이 나오는 행 번호와 행을 돌려준다.
import '../../data/models/poem.dart';
import 'poem_text.dart';

class LineMatch {
  const LineMatch({required this.lineNo, required this.line});

  final int lineNo; // 1부터
  final String line;

  /// 모델에게 돌려줄 결과
  Map<String, Object?> toJson() => {'lineNo': lineNo, 'line': line};
}

List<LineMatch> searchPoemLines(Poem poem, String word) {
  final normalized = normalizeQuote(word);
  if (normalized.isEmpty) return const [];
  return [
    for (var lineNo = 1; lineNo <= poem.lines.length; lineNo++)
      if (poem.lineAt(lineNo).contains(normalized))
        LineMatch(lineNo: lineNo, line: poem.lineAt(lineNo)),
  ];
}
