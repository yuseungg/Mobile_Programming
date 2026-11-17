// 주인: D — 비교 문장 검사 (기획서 6장 「모델 출력 제어」 · 지침서 제품 원칙 6)
//
// A의 OutputGuard를 통째로 쓸 수 없다. 그 검사는 「물음표로 끝나야 한다」를
// 요구하지만(S05는 질문만 한다), 비교 문장은 질문이 아니다.
// 그래서 여기서는 비교 문장에 맞는 것만 본다.
//
// 쓰지 않는 말 목록은 A의 OutputGuard와 한 곳에서 가져온다. 두 군데에
// 적어 두면 한쪽만 고쳐지는 일이 생긴다.
//
// 인용 검사가 이 파일의 핵심이다. 모델이 시에 없는 구절을 따옴표에 넣어
// 내보내면 사용자는 그것을 원문으로 읽는다. 그래서 따옴표 안의 말이
// 모델에게 준 재료(시 원문 · 내 해석 · 전문가 해석) 안에 실제로 있는지
// 코드로 확인하고, 없으면 그 문장을 버린다.

import '../agent/output_guard.dart';
import 'comparison_writer.dart';

/// 걸린 이유. 다시 쓰게 할 때 모델에게 그대로 알려 준다.
enum ComparisonViolation {
  empty, // 비어 있음
  forbiddenWord, // 앱에서 쓰지 않는 말
  assertive, // 단정형 — "~을 뜻한다", "~을 상징한다" 계열
  tooLong, // 세 문장을 넘음
  unknownQuote, // 따옴표 안의 말이 준 재료에 없음
  unknownLine, // 시에 없는 행 번호를 불렀음
}

class ComparisonGuard {
  ComparisonGuard._();

  static const maxSentences = 3;

  static final _quotedSpan =
      RegExp(r'''['‘]([^'’]*)['’]|["“]([^"”]*)["”]|「([^」]*)」|『([^』]*)』''');
  // 되묻는 말이 아니라 단정이다. "입니다"는 여기서 보지 않는다 —
  // 비교 문장은 질문이 아니라 서술이라 말끝 규칙이 S05와 다르다.
  static final _assertive =
      RegExp(r'(뜻|의미|상징|암시|은유)(한다|합니다|하는 것)|나타낸다|나타냅니다');
  static final _sentenceBreak = RegExp(r'(?<=[.!?。！？])\s+|\n+');
  static final _lineNumber = RegExp(r'(\d+)\s*행');
  static final _whitespace = RegExp(r'\s+');

  /// 앞뒤 공백과 마크다운 강조 기호를 정리한다 (A의 clean과 같은 규칙).
  static String clean(String text) => OutputGuard.clean(text);

  /// 모델에게 준 재료. 따옴표 안의 말은 이 안에 있어야 한다.
  static List<String> quotableSources(ComparisonRequest request) => [
        ...request.poem.lines,
        request.myInterpretation,
        request.expert.stance,
        for (final claim in request.expert.claims) claim.point,
      ];

  static List<ComparisonViolation> check(
    String text,
    ComparisonRequest request,
  ) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return const [ComparisonViolation.empty];

    final unquoted = trimmed.replaceAll(_quotedSpan, 'Q');
    final haystack = quotableSources(request)
        .map((source) => source.replaceAll(_whitespace, ''))
        .where((source) => source.isNotEmpty)
        .toList();
    final lineCount = request.poem.lines.length;

    return [
      if (OutputGuard.forbiddenWords.any(trimmed.contains))
        ComparisonViolation.forbiddenWord,
      if (_assertive.hasMatch(unquoted)) ComparisonViolation.assertive,
      if (_sentenceCount(unquoted) > maxSentences) ComparisonViolation.tooLong,
      if (_quotesOf(trimmed).any((quote) => !haystack.any(quote.contains)))
        ComparisonViolation.unknownQuote,
      if (_lineNumbersOf(trimmed)
          .any((lineNo) => lineNo < 1 || lineNo > lineCount))
        ComparisonViolation.unknownLine,
    ];
  }

  /// 따옴표 안의 말들. 공백을 지우고 비교한다 — 행이 바뀌는 자리에서
  /// 띄어쓰기가 달라지는 것으로 없는 인용이 되면 안 된다.
  /// 한 글자는 보지 않는다 ("A" 같은 이름표까지 막게 된다).
  static List<String> _quotesOf(String text) => [
        for (final match in _quotedSpan.allMatches(text))
          if (_innerOf(match).replaceAll(_whitespace, '').length > 1)
            _innerOf(match).replaceAll(_whitespace, ''),
      ];

  static String _innerOf(RegExpMatch match) {
    for (var group = 1; group <= match.groupCount; group++) {
      final inner = match.group(group);
      if (inner != null) return inner;
    }
    return '';
  }

  static List<int> _lineNumbersOf(String text) => [
        for (final match in _lineNumber.allMatches(text))
          int.parse(match.group(1)!),
      ];

  static int _sentenceCount(String text) => text
      .split(_sentenceBreak)
      .where((sentence) => sentence.trim().isNotEmpty)
      .length;
}

String comparisonViolationReason(ComparisonViolation violation) =>
    switch (violation) {
      ComparisonViolation.empty => '문장이 비어 있음',
      ComparisonViolation.forbiddenWord => '쓰지 않는 말이 있음',
      ComparisonViolation.assertive => '단정하는 말이 있음',
      ComparisonViolation.tooLong => '세 문장을 넘음',
      ComparisonViolation.unknownQuote => '준 재료에 없는 말을 따옴표에 넣었음',
      ComparisonViolation.unknownLine => '시에 없는 행 번호를 불렀음',
    };
