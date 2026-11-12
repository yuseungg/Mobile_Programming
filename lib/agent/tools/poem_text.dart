// 주인: A — 툴들이 같이 쓰는 글자 다듬기
import '../../data/models/poem.dart';

const _quoteMarks = '\'"‘’“”「」『』';
const _edgePunctuation = '.,!?…·';
final _spaces = RegExp(r'\s+');
final _lineReference = RegExp(r'(\d+)\s*행');

/// 공백을 한 칸으로 줄이고, 앞뒤의 따옴표 · 문장부호를 뗀다.
String normalizeQuote(String text) {
  var result = collapseSpaces(text);
  bool isEdge(String char) =>
      char == ' ' || _quoteMarks.contains(char) || _edgePunctuation.contains(char);
  while (result.isNotEmpty && isEdge(result[0])) {
    result = result.substring(1);
  }
  while (result.isNotEmpty && isEdge(result[result.length - 1])) {
    result = result.substring(0, result.length - 1);
  }
  return result;
}

/// 공백만 한 칸으로 줄인다. 사용자 말 안에 구절이 들어 있는지 볼 때 쓴다.
String collapseSpaces(String text) => text.replaceAll(_spaces, ' ').trim();

/// 글에서 "N행"으로 짚은 행 번호. 나온 순서대로, 시에 실제로 있는 행만 (1부터, 빈 줄 제외)
List<int> lineNosMentioned(String text, Poem poem) {
  final lineNos = <int>[];
  for (final match in _lineReference.allMatches(text)) {
    final lineNo = int.tryParse(match.group(1)!);
    if (lineNo == null) continue;
    final isRealLine = lineNo >= 1 &&
        lineNo <= poem.lines.length &&
        poem.lineAt(lineNo).isNotEmpty;
    if (isRealLine && !lineNos.contains(lineNo)) lineNos.add(lineNo);
  }
  return lineNos;
}
