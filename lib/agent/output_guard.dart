// 주인: A — 출력 필터 (기획서 6장 「모델 출력 제어」)
// 프롬프트로 "질문만 하라"고 해도 턴이 쌓이면 해설이 새어 나온다.
// 그래서 화면에 보내기 전에 코드로 한 번 더 검사하고, 걸리면 다시 쓰게 한다.

/// 걸린 이유. 다시 쓰게 할 때 모델에게 그대로 알려 준다.
enum GuardViolation {
  empty, // 비어 있음
  notQuestion, // 물음표로 끝나지 않음
  multipleQuestions, // 한 번에 둘 이상 물음 (지침서 원칙 1: 한 번에 하나만)
  assertive, // 단정형 — "~을 뜻한다", "~을 상징한다", "~입니다" 계열
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

  // 따옴표 안(시 구절 · 사용자 말 인용)은 물음표 · 문장 수 · 단정형 검사에서 뺀다
  static final _quotedSpan =
      RegExp(r'''['‘][^'’]*['’]|["“][^"”]*["”]|「[^」]*」|『[^』]*』''');
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
      if (_assertive.hasMatch(unquoted)) GuardViolation.assertive,
      if (forbiddenWords.any(trimmed.contains)) GuardViolation.forbiddenWord,
      if (_sentenceCount(unquoted) > maxSentences) GuardViolation.tooLong,
    ]);
  }

  static int _sentenceCount(String text) => text
      .split(_sentenceBreak)
      .where((sentence) => sentence.trim().isNotEmpty)
      .length;
}
