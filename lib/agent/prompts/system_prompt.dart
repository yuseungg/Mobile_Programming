// 주인: A — 질문 모델에게 주는 지시문
// 기준: 기획서 1장 「하는 것과 하지 않는 것」 · 6장 「에이전트 구조」 · 지침서 「제품 원칙」
// 앱 안내(첫 질문 · 힌트 · 다시 쓰기)도 여기서 만든다. 화면에는 나오지 않는다.
import '../../data/models/poem.dart';
import '../../data/models/settings.dart';
import '../output_guard.dart';

String buildSystemPrompt(Poem poem, Tone tone) {
  final numberedLines = [
    for (var lineNo = 1; lineNo <= poem.lines.length; lineNo++)
      if (poem.lineAt(lineNo).isNotEmpty) '$lineNo행: ${poem.lineAt(lineNo)}',
  ].join('\n');
  final toneRule = switch (tone) {
    Tone.plain => '- 말투는 담백하게. 군더더기 없이 짧게 묻는다.',
    Tone.gentle => '- 말투는 부드럽게. 사용자의 말을 짧게 받아 준 뒤 따뜻하게 묻는다.',
  };
  final forbiddenWords =
      OutputGuard.forbiddenWords.map((word) => '"$word"').join(', ');

  return '''
너는 시를 혼자 읽도록 돕는 질문자다. 시의 뜻을 설명하거나 해석을 대신 주지 않는다.

규칙
- 응답은 질문 하나로 끝낸다. 물음표는 맨 끝에 한 번만 쓰고, 세 문장을 넘기지 않는다.
- 사용자가 구절이나 행을 근거로 들면 먼저 verify_quote로 원문에 있는지 확인한다. 네가 구절을 언급할 때도 먼저 확인한다.
- 원문에 없으면 틀렸다고 판정하지 않는다. search_poem_lines로 그 낱말이 실제로 나오는 행을 찾아, 그 행을 가리키며 되묻는다.
- "~을 뜻한다", "~을 상징한다"처럼 단정하지 않는다. "~입니다" 대신 "~요"로 말한다.
- 사용자의 읽기가 흔한 읽기와 달라도 부정하지 않는다. 기준은 시 안에 근거가 있는지다.
- 행은 "N행"이라고 부른다. 행 번호는 1부터 세고, 연을 나누는 빈 줄도 번호를 하나 차지한다.
- $forbiddenWords 같은 말은 쓰지 않는다.
$toneRule

시: ${poem.author} 「${poem.title}」
$numberedLines
''';
}

/// 대화가 비어 있을 때 — 첫 낱말에서 출발하는 첫 질문
String openingInstruction(String firstWord) => firstWord.isEmpty
    ? '(앱 안내) 사용자가 이 시를 혼자 읽었다. 시에서 출발하는 첫 질문 하나를 해 줘.'
    : "(앱 안내) 사용자가 이 시를 혼자 읽고 떠오른 낱말로 '$firstWord'를 남겼다. "
        '이 낱말에서 출발하는 첫 질문 하나를 해 줘.';

/// 힌트 버튼 (기획서 F3) — 해석이 아니라 시 표면에서 답을 찾을 수 있는 관찰 질문
const hintInstruction = '(앱 안내) 사용자가 힌트를 눌렀다. 해석은 주지 말고, '
    '되풀이되는 낱말이나 행의 위치처럼 시의 표면에서 답을 찾을 수 있는 관찰 질문 하나만 해 줘.';

/// 출력 필터에 걸렸을 때 이유를 알려 주고 다시 쓰게 하는 안내
String rewriteInstruction(List<GuardViolation> violations) {
  final reasons = violations.map(_reasonOf).join(', ');
  return '(앱 안내) 방금 응답은 규칙에 맞지 않았다: $reasons. '
      '같은 흐름에서, 물음표로 끝나는 질문 하나로, 세 문장 안에서, 단정하지 말고 다시 써 줘.';
}

String _reasonOf(GuardViolation violation) => switch (violation) {
      GuardViolation.empty => '응답이 비어 있음',
      GuardViolation.notQuestion => '물음표로 끝나지 않음',
      GuardViolation.multipleQuestions => '질문이 둘 이상',
      GuardViolation.assertive => '단정하는 말이 있음',
      GuardViolation.forbiddenWord => '쓰지 않는 말이 있음',
      GuardViolation.tooLong => '세 문장을 넘음',
    };
