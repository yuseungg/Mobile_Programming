// 주인: D — 비교 모델에게 주는 지시문 (기획서 4장 「대조」 · 1장 「쓰지 않는 말」)
//
// 두 가지를 프롬프트가 지킨다.
//  1. 관계는 코드가 이미 정했다. 모델에게 관계 문구를 **주고**, 다시 판단하지 말라고 한다.
//  2. 공통점부터 말하고, 사용자가 놓친 것을 가리키지 않는다.
//
// 지키지 못했을 때 걸러내는 쪽은 comparison_guard.dart다. 프롬프트만으로는
// 턴이 쌓이면 새어 나온다 (A가 OutputGuard를 둔 것과 같은 이유).

import '../agent/output_guard.dart';
import '../app/strings.dart';
import '../compare/relation.dart';
import '../data/models/expert_interpretation.dart';
import '../data/models/settings.dart';
import 'comparison_guard.dart';
import 'comparison_writer.dart';

/// 비교 문장 하나를 쓰게 하는 메시지 묶음 (툴 없이 한 번 부른다)
List<Map<String, Object?>> buildComparisonMessages({
  required ComparisonRequest request,
  required Tone tone,
}) =>
    [
      {'role': 'system', 'content': _systemPrompt(request, tone)},
      {'role': 'user', 'content': _materials(request)},
    ];

String _systemPrompt(ComparisonRequest request, Tone tone) {
  final forbiddenWords =
      OutputGuard.forbiddenWords.map((word) => '"$word"').join(', ');
  final toneRule = switch (tone) {
    Tone.plain => '- 말투는 담백하게. 군더더기 없이 짧게 적는다.',
    Tone.gentle => '- 말투는 부드럽게. 두 읽기를 함께 감싸듯 적는다.',
  };

  return '''
너는 한 사람이 쓴 해석과 전문가 해석을 나란히 놓고, 두 읽기가 어떻게 만나는지
한두 문장으로 적는 사람이다. 어느 쪽이 맞는지 가리지 않는다.

규칙
- 관계는 이미 정해져 있다: "${_relationText(request)}". 이 관계를 다시 판단하거나 뒤집지 않는다.
- 공통점을 먼저 적는다. 두 읽기가 함께 본 행이 있으면 그 행에서 출발한다.
- 사용자의 읽기를 고치지 않는다. 모자라다고 하지 않고, 놓친 것을 가르치지 않는다.
- 아래에 준 재료에 없는 말을 따옴표에 넣지 않는다. 인용은 재료에 있는 그대로만 옮긴다.
- 행은 "N행"이라고 부른다. 행 번호는 1부터 세고, 연을 나누는 빈 줄도 번호를 하나 차지한다.
  준 시의 마지막 행은 ${request.poem.lines.length}행이다. 그보다 큰 번호를 부르지 않는다.
- "~을 뜻한다", "~을 상징한다"처럼 단정하지 않는다. "~입니다" 대신 "~요"로 적는다.
- $forbiddenWords 같은 말은 쓰지 않는다.
- 세 문장을 넘기지 않는다. 질문하지 않는다. 문장만 적고 다른 말을 붙이지 않는다.
$toneRule
''';
}

String _materials(ComparisonRequest request) {
  final poem = request.poem;
  final numberedLines = [
    for (var lineNo = 1; lineNo <= poem.lines.length; lineNo++)
      if (poem.lineAt(lineNo).isNotEmpty) '$lineNo행: ${poem.lineAt(lineNo)}',
  ].join('\n');
  final theirLines = expertLines(request.expert);
  final shared = (request.myEvidenceLines.toSet().intersection(theirLines.toSet())
        .toList()
    ..sort());

  return '''
시: ${poem.author} 「${poem.title}」
$numberedLines

[내 해석]
근거 행: ${_lineList(request.myEvidenceLines)}
${request.myInterpretation.trim().isEmpty ? '(비어 있음)' : request.myInterpretation.trim()}

[${request.expert.label}]
입장: ${request.expert.stance}
근거 행: ${_lineList(theirLines)}
${[for (final claim in request.expert.claims) '- ${_lineList(claim.lines)}: ${claim.point}'].join('\n')}

함께 본 행: ${shared.isEmpty ? '없음' : _lineList(shared)}
관계: ${_relationText(request)}
''';
}

/// 걸렸을 때 이유를 알려 주고 다시 쓰게 하는 안내
String comparisonRewriteInstruction(List<ComparisonViolation> violations) {
  final reasons = violations.map(comparisonViolationReason).join(', ');
  return '(앱 안내) 방금 문장은 규칙에 맞지 않았다: $reasons. '
      '같은 관계를 그대로 두고, 공통점부터, 세 문장 안에서, 단정하지 말고 다시 적어 줘.';
}

String _relationText(ComparisonRequest request) => switch (request.relation) {
      Relation.sameLines => AppStrings.comparisonRelationSameLines,
      Relation.partialOverlap => AppStrings.comparisonRelationPartialOverlap,
      Relation.differentLines =>
        AppStrings.comparisonRelationDifferentLines(expertLines(request.expert)),
    };

String _lineList(List<int> lines) =>
    lines.isEmpty ? '없음' : AppStrings.lineList(lines);
