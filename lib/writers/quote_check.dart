// 주인: D — 인용 검사 (지침서 제품 원칙 6 「인용은 원문 부분 문자열인지 코드로 검사한다」)
//
// 비교 문장(S07)과 대화 요약(S09)이 같은 검사를 쓴다. 두 군데에 적어 두면
// 한쪽만 고쳐지는 일이 생기므로 여기 한 곳에 둔다.
//
// 모델이 따옴표에 넣어 내보낸 말은 사용자가 원문으로 읽는다. 그래서 그 말이
// 모델에게 **준 재료** 안에 실제로 있는지 확인하고, 없으면 그 문장을 버린다.

final _quotedSpan =
    RegExp(r'''['‘]([^'’]*)['’]|["“]([^"”]*)["”]|「([^」]*)」|『([^』]*)』''');
final _whitespace = RegExp(r'\s+');

/// 따옴표 밖의 말. 문장 수 · 단정형 검사는 인용을 빼고 본다.
String withoutQuotes(String text) => text.replaceAll(_quotedSpan, 'Q');

/// 따옴표 안의 말들 (공백을 지운 형태).
/// 한 글자는 보지 않는다 — "A" 같은 이름표까지 막게 된다.
List<String> quotesIn(String text) => [
      for (final match in _quotedSpan.allMatches(text))
        if (_squash(_innerOf(match)).length > 1) _squash(_innerOf(match)),
    ];

/// 따옴표 안의 말이 모두 [sources] 안에 있는가.
/// 공백을 지우고 비교한다 — 행이 바뀌는 자리에서 띄어쓰기가 달라지는 것으로
/// 있는 인용이 없는 인용이 되면 안 된다.
bool quotesAreGrounded(String text, Iterable<String> sources) {
  final quotes = quotesIn(text);
  if (quotes.isEmpty) return true;
  final haystack = [
    for (final source in sources)
      if (_squash(source).isNotEmpty) _squash(source),
  ];
  return quotes.every((quote) => haystack.any(quote.contains));
}

String _squash(String text) => text.replaceAll(_whitespace, '');

String _innerOf(RegExpMatch match) {
  for (var group = 1; group <= match.groupCount; group++) {
    final inner = match.group(group);
    if (inner != null) return inner;
  }
  return '';
}
