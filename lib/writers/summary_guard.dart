// 주인: D — 대화 요약 검사 (기획서 F7 「AI 요약」 · 지침서 제품 원칙 3 · 6)
//
// 요약은 **남이 읽는 글**이다. 비교 문장(S07)보다 검사가 엄하다.
//  - 질문이 아니다. 물음표가 있으면 요약이 아니라 질문이다.
//  - 평가하지 않는다. 해석의 질로 점수 · 순위 · 보상을 주지 않는다(원칙 3).
//    "깊은 읽기였어요" 같은 말이 공개 대화에 붙으면 그게 곧 순위가 된다.
//  - 대화에 없던 말을 따옴표에 넣지 않는다 (원칙 6, quote_check.dart).
//
// 쓰지 않는 말 목록은 A의 OutputGuard에서 가져온다 (한 곳에만 적는다).

import '../agent/output_guard.dart';
import 'quote_check.dart';
import 'summary_writer.dart';

enum SummaryViolation {
  empty, // 비어 있음
  forbiddenWord, // 앱에서 쓰지 않는 말
  evaluative, // 해석을 평가하는 말
  question, // 물음표가 있음 — 요약은 질문이 아니다
  assertive, // 단정형 — "~을 뜻한다", "~을 상징한다" 계열
  tooLong, // 두 문장 또는 글자 수를 넘음
  unknownQuote, // 따옴표 안의 말이 대화에 없음
}

class SummaryGuard {
  SummaryGuard._();

  static const maxSentences = 2;

  /// S09 카드 안에 들어가는 글이다. 넘치면 화면이 밀린다.
  static const maxChars = 150;

  /// 해석의 질을 말하는 낱말. 공개 대화에 붙으면 그게 순위가 된다 (원칙 3).
  static const evaluativeWords = [
    '훌륭',
    '뛰어난',
    '탁월',
    '깊은 읽기',
    '깊이 있는',
    '아쉽',
    '부족',
    '미흡',
    '수준',
    '모범',
  ];

  static final _assertive =
      RegExp(r'(뜻|의미|상징|암시|은유)(한다|합니다|하는 것)|나타낸다|나타냅니다');
  static final _sentenceBreak = RegExp(r'(?<=[.!?。！？])\s+|\n+');
  static final _questionMark = RegExp(r'[?？]');

  static String clean(String text) => OutputGuard.clean(text);

  /// 요약이 기댈 수 있는 재료. 따옴표 안의 말은 이 안에 있어야 한다.
  static List<String> quotableSources(SummaryRequest request) => [
        request.firstWord,
        request.interpretation,
        for (final message in request.conversation) message.text,
      ];

  static List<SummaryViolation> check(String text, SummaryRequest request) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return const [SummaryViolation.empty];

    final unquoted = withoutQuotes(trimmed);

    return [
      if (OutputGuard.forbiddenWords.any(trimmed.contains))
        SummaryViolation.forbiddenWord,
      if (evaluativeWords.any(trimmed.contains)) SummaryViolation.evaluative,
      if (_questionMark.hasMatch(unquoted)) SummaryViolation.question,
      if (_assertive.hasMatch(unquoted)) SummaryViolation.assertive,
      if (_sentenceCount(unquoted) > maxSentences ||
          trimmed.length > maxChars)
        SummaryViolation.tooLong,
      if (!quotesAreGrounded(trimmed, quotableSources(request)))
        SummaryViolation.unknownQuote,
    ];
  }

  static int _sentenceCount(String text) => text
      .split(_sentenceBreak)
      .where((sentence) => sentence.trim().isNotEmpty)
      .length;
}

String summaryViolationReason(SummaryViolation violation) =>
    switch (violation) {
      SummaryViolation.empty => '요약이 비어 있음',
      SummaryViolation.forbiddenWord => '쓰지 않는 말이 있음',
      SummaryViolation.evaluative => '해석을 평가하는 말이 있음',
      SummaryViolation.question => '물음표가 있음 (요약은 질문이 아니다)',
      SummaryViolation.assertive => '단정하는 말이 있음',
      SummaryViolation.tooLong => '두 문장 또는 150자를 넘음',
      SummaryViolation.unknownQuote => '대화에 없는 말을 따옴표에 넣었음',
    };
