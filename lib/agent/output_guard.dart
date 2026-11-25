// 주인: A — 출력 필터 (기획서 6장 「모델 출력 제어」)
// 프롬프트로 "질문만 하라"고 해도 턴이 쌓이면 해설이 새어 나온다.
// 그래서 화면에 보내기 전에 코드로 한 번 더 검사하고, 걸리면 다시 쓰게 한다.
//
// 한국어 · 영어 응답을 모두 본다 (화면 오른쪽 위 KR / EN). 검사는 언어를 묻지 않는다 —
// 한국어 규칙은 영어 글에, 영어 규칙은 한국어 글에 걸릴 일이 없어서 둘 다 늘 돌린다.

/// 걸린 이유. 다시 쓰게 할 때 모델에게 그대로 알려 준다.
enum GuardViolation {
  empty, // 비어 있음
  notQuestion, // 물음표로 끝나지 않음
  multipleQuestions, // 한 번에 둘 이상 물음 (지침서 원칙 1: 한 번에 하나만)
  assertive, // 단정형 — "~을 뜻한다", "~을 상징한다", "~입니다" · "this means …" 계열
  forbiddenWord, // 앱에서 쓰지 않는 말
  tooLong, // 세 문장을 넘음
}

class GuardResult {
  const GuardResult(this.violations);

  final List<GuardViolation> violations;

  bool get isPassed => violations.isEmpty;
}

class OutputGuard {
  OutputGuard._();

  static const maxSentences = 3;

  /// 앱에서 쓰지 않는 말 (기획서 1장 「쓰지 않는 말」). 화면에 나가지 않게 막으려고 여기에 적는다.
  static const forbiddenWords = ['정답', '해설', '올바른'];

  /// 같은 뜻의 영어. 대소문자를 가리지 않고 낱말 단위로 본다 (correctly도 걸린다).
  static const forbiddenWordsEnglish = [
    'correct',
    'right answer',
    'the answer',
    'explanation',
    'commentary',
  ];
  static final _forbiddenEnglish = RegExp(
    r'\b(correct\w*|right answers?|the answers?|explanations?|commentar(y|ies))\b',
    caseSensitive: false,
  );

  /// 영어 단정형. 뜻을 못박는 말 — 되묻는 문장(물음표로 끝나는)에서는 보지 않는다.
  /// "What do you think the wind represents?"는 되묻기, "The wind represents trials."는 단정.
  static final englishAssertive = RegExp(
    r"\b(means|symboli[sz]es|represents|signifies|stands for|"
    r'is a (symbol|metaphor) (of|for)|is about)\b',
    caseSensitive: false,
  );

  /// 글에 쓰지 않는 말이 있는가 (한국어 · 영어). 비교 문장 · 요약 검사도 이것을 쓴다.
  static bool hasForbiddenWord(String text) =>
      forbiddenWords.any(text.contains) || _forbiddenEnglish.hasMatch(text);

  // 따옴표 안(시 구절 · 사용자 말 인용)은 물음표 · 문장 수 · 단정형 검사에서 뺀다.
  // 곧은 작은따옴표는 영어 낱말 사이(don't · it's)에서는 따옴표가 아니다.
  static final _quotedSpan = RegExp(
      r'''(?<![A-Za-z])['‘](?:[^'’]|(?<=[A-Za-z])['’](?=[A-Za-z]))*['’](?![A-Za-z])|["“][^"”]*["”]|「[^」]*」|『[^』]*』''');
  // "상징한다고 느꼈나요?"처럼 되묻는 말(…고)은 단정형으로 보지 않는다
  static final _assertive =
      RegExp(r'(뜻|의미|상징|암시|은유)(한다|합니다)(?!고)|나타낸다|나타냅니다|입니다');
  static final _sentenceBreak = RegExp(r'(?<=[.!?。！？])\s+|\n+');
  static final _questionMark = RegExp(r'[?？]');

  /// 앞뒤 공백 · 빈 줄과 마크다운 강조 기호를 정리한다.
  static String clean(String text) =>
      text.replaceAll('**', '').replaceAll('__', '').trim();

  static GuardResult check(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return const GuardResult([GuardViolation.empty]);

    final unquoted = trimmed.replaceAll(_quotedSpan, 'Q');
    return GuardResult([
      if (!trimmed.endsWith('?') && !trimmed.endsWith('？'))
        GuardViolation.notQuestion,
      if (_questionMark.allMatches(unquoted).length > 1)
        GuardViolation.multipleQuestions,
      if (_assertive.hasMatch(unquoted) || _statesEnglishMeaning(unquoted))
        GuardViolation.assertive,
      if (hasForbiddenWord(trimmed)) GuardViolation.forbiddenWord,
      if (_sentenceCount(unquoted) > maxSentences) GuardViolation.tooLong,
    ]);
  }

  /// 물음표로 끝나지 않는 영어 문장에 뜻을 못박는 말이 있는가
  static bool _statesEnglishMeaning(String text) => _sentencesOf(text).any(
        (sentence) =>
            !sentence.trimRight().endsWith('?') &&
            englishAssertive.hasMatch(sentence),
      );

  static Iterable<String> _sentencesOf(String text) => text
      .split(_sentenceBreak)
      .where((sentence) => sentence.trim().isNotEmpty);

  static int _sentenceCount(String text) => _sentencesOf(text).length;
}
