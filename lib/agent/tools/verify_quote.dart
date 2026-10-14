// 주인: A — 툴 verify_quote (기획서 6장)
// 인용한 구절이 원문에 그대로 있는지 코드로 검사한다. 모델의 말을 믿지 않는다.
// 행 번호는 1부터. 연 구분 빈 줄도 번호를 하나 차지한다.
import '../../data/models/poem.dart';
import 'poem_text.dart';

/// verify_quote의 결과
class QuoteCheck {
  const QuoteCheck({required this.quote, required this.lineNos});

  final String quote; // 따옴표 · 끝 문장부호를 뗀 구절
  final List<int> lineNos; // 구절이 들어 있는 행. 비어 있으면 원문에 없다

  bool get isFound => lineNos.isNotEmpty;

  /// 모델에게 돌려줄 결과
  Map<String, Object?> toJson() => isFound
      ? {'found': true, 'quote': quote, 'lines': lineNos}
      : {'found': false, 'quote': quote};
}

QuoteCheck verifyQuote(Poem poem, String quote) {
  final normalized = normalizeQuote(quote);
  if (normalized.isEmpty) return QuoteCheck(quote: normalized, lineNos: const []);

  // 한 행 안에 있는 경우 — 되풀이되면 그 행 전부
  final lineNos = [
    for (var lineNo = 1; lineNo <= poem.lines.length; lineNo++)
      if (poem.lineAt(lineNo).contains(normalized)) lineNo,
  ];
  if (lineNos.isNotEmpty) return QuoteCheck(quote: normalized, lineNos: lineNos);

  return QuoteCheck(quote: normalized, lineNos: _acrossLines(poem, normalized));
}

/// 행을 넘어가는 구절 — 빈 줄을 빼고 행을 한 칸씩 띄어 이은 글에서 찾는다.
List<int> _acrossLines(Poem poem, String quote) {
  final joined = StringBuffer();
  final spans = <({int lineNo, int start, int end})>[];
  for (var lineNo = 1; lineNo <= poem.lines.length; lineNo++) {
    final line = poem.lineAt(lineNo);
    if (line.isEmpty) continue;
    if (joined.isNotEmpty) joined.write(' ');
    final start = joined.length;
    joined.write(line);
    spans.add((lineNo: lineNo, start: start, end: joined.length));
  }

  final start = joined.toString().indexOf(quote);
  if (start < 0) return const [];
  final end = start + quote.length;
  return [
    for (final span in spans)
      if (span.start < end && span.end > start) span.lineNo,
  ];
}
