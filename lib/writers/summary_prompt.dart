// 주인: D — 요약 모델에게 주는 지시문 (기획서 F7 「AI 요약」)
//
// 요약은 공개 대화 문서에 담겨 **남이 읽는다.** 그래서 지시문이 막는 것이
// 비교 문장보다 많다: 평가하지 않기(원칙 3), 대화를 그대로 옮기지 않기,
// 대화에 없는 것을 넣지 않기(원칙 6).
//
// 걸러내는 쪽은 summary_guard.dart다. 지시문만으로는 새어 나온다.

import '../agent/output_guard.dart';
import '../data/models/poem.dart';
import '../data/models/settings.dart';
import 'summary_guard.dart';
import 'summary_writer.dart';

/// 요약 하나를 쓰게 하는 메시지 묶음 (툴 없이 한 번 부른다)
List<Map<String, Object?>> buildSummaryMessages({
  required SummaryRequest request,
  required Poem poem,
  required Tone tone,
}) =>
    [
      {'role': 'system', 'content': _systemPrompt(request, tone)},
      {'role': 'user', 'content': _materials(request, poem)},
    ];

String _systemPrompt(SummaryRequest request, Tone tone) {
  final forbiddenWords =
      OutputGuard.forbiddenWords.map((word) => '"$word"').join(', ');
  final toneRule = switch (tone) {
    Tone.plain => '- 말투는 담백하게.',
    Tone.gentle => '- 말투는 부드럽게.',
  };

  return '''
너는 한 사람이 시를 읽고 AI와 나눈 대화를, 그 사람의 공개 글에 붙는
짧은 요약으로 적는 사람이다. 이 글은 다른 사람들이 읽는다.

규칙
- 대화에 **실제로 있었던 것만** 적는다. 짐작해서 보태지 않는다.
- 대화를 그대로 옮기지 않는다. 어디서 시작해 어디로 갔는지만 적는다.
- 해석을 평가하지 않는다. 좋다 · 깊다 · 아쉽다처럼 값을 매기는 말을 쓰지 않는다.
  이 앱은 해석의 질로 점수나 순위를 주지 않는다.
- 아래 재료에 없는 말을 따옴표에 넣지 않는다. 인용은 재료에 있는 그대로만 옮긴다.
- 첫 낱말 「${request.firstWord}」에서 시작한 대화다. 거기서 출발해 적는다.
- 질문하지 않는다. 물음표를 쓰지 않는다.
- "~을 뜻한다", "~을 상징한다"처럼 단정하지 않는다. "~입니다" 대신 "~요"로 적는다.
- $forbiddenWords 같은 말은 쓰지 않는다.
- ${SummaryGuard.maxSentences}문장 안에서, ${SummaryGuard.maxChars}자 안에서 끝낸다. 요약만 적고 다른 말을 붙이지 않는다.
$toneRule
''';
}

String _materials(SummaryRequest request, Poem poem) {
  final numberedLines = [
    for (var lineNo = 1; lineNo <= poem.lines.length; lineNo++)
      if (poem.lineAt(lineNo).isNotEmpty) '$lineNo행: ${poem.lineAt(lineNo)}',
  ].join('\n');
  final transcript = [
    for (final message in request.conversation)
      '${message.isUser ? '사용자' : 'AI'}: ${message.text}',
  ].join('\n');

  return '''
시: ${poem.author} 「${poem.title}」
$numberedLines

첫 낱말: ${request.firstWord}

[대화]
$transcript

[사용자가 저장한 최종 해석]
${request.interpretation.trim().isEmpty ? '(비어 있음)' : request.interpretation.trim()}
''';
}

/// 걸렸을 때 이유를 알려 주고 다시 쓰게 하는 안내
String summaryRewriteInstruction(List<SummaryViolation> violations) {
  final reasons = violations.map(summaryViolationReason).join(', ');
  return '(앱 안내) 방금 요약은 규칙에 맞지 않았다: $reasons. '
      '대화에 있던 것만, ${SummaryGuard.maxSentences}문장 안에서, 평가하지 말고 다시 적어 줘.';
}
