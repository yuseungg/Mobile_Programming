// 주인: D — 에이전트 툴 compare_with_experts · get_poem_context의 본체 (기획서 6장 「툴」)
//
// A의 lib/agent/tools/agent_tools.dart가 이 두 함수를 부른다. 경계 규칙:
//
//  1. 여기서는 lib/agent/를 import 하지 않는다. 돌려주는 것은 평범한
//     Map<String, Object?>이고, A가 ToolResult로 감싼다.
//  2. 두 함수는 순수하고 동기다. A의 `ToolResult run(...)`이 동기라서,
//     여기서 에셋을 직접 읽으면 Future가 되어 A의 디스패처를 바꿔야 한다.
//     그래서 필요한 데이터는 호출하는 쪽이 인자로 넣어 준다.
//  3. 저장 전 거부와 isSaved 잠금은 A 쪽에 이미 있다. 여기서 다시 막지 않는다.
//
// A가 해야 하는 연결 (2줄):
//   case compareWithExpertsName:
//     return ToolResult(compareWithExperts(
//       myEvidenceLines: myEvidenceLines, myInterpretation: myInterpretation,
//       experts: experts));
//   case getPoemContextName:
//     return ToolResult(getPoemContext(poem: poem));
// → AgentTools에 myEvidenceLines · myInterpretation · experts 세 필드가 더 필요하다.

import '../data/models/expert_interpretation.dart';
import '../data/models/poem.dart';
import 'relation.dart';

/// `compare_with_experts` — 내 해석과 전문가 해석의 관계를 돌려준다.
///
/// 관계는 코드가 정한다 (기획서 4장). 모델은 이 결과를 말로 풀기만 한다.
/// 관계의 화면 문구(「같은 곳을 봤어요」 등)는 AppStrings가 가지므로
/// 여기서는 Relation 이름만 넘긴다.
///
/// 전문가만 근거로 삼은 행은 **일부러 넣지 않는다.** 기획서 4장이
/// "전문가는 이 줄도 봤다"처럼 내가 놓친 것을 가리키는 문장을 금지한다.
/// 금지된 문장의 재료를 모델에게 미리 씹어 주지 않는다.
/// (claims 안의 lines로 모델이 계산할 수는 있다. 그건 프롬프트가 막는다.)
Map<String, Object?> compareWithExperts({
  required List<int> myEvidenceLines,
  required String myInterpretation,
  required List<ExpertInterpretation> experts,
}) {
  final mine = myEvidenceLines.toSet();
  return {
    'mine': {
      'lines': mine.toList()..sort(),
      'interpretation': myInterpretation,
    },
    'experts': [
      for (final expert in experts)
        {
          'label': expert.label,
          'stance': expert.stance,
          'relation': computeRelation(myEvidenceLines, expert).name,
          'shared_lines': mine.intersection(expertLines(expert).toSet()).toList()
            ..sort(),
          'claims': [
            for (final claim in expert.claims)
              {'lines': claim.lines, 'point': claim.point},
          ],
        },
    ],
  };
}

/// `get_poem_context` — 창작 배경을 돌려준다.
///
/// 기획서 7장: 창작 배경은 **사실만** 담고 해석과 별도 필드다.
/// 해석을 섞어 보내지 않도록 Poem.creationBackground만 넘긴다.
Map<String, Object?> getPoemContext({required Poem poem}) {
  return {
    'poem': poem.poemId,
    'title': poem.title,
    'author': poem.author,
    'year': poem.year,
    'creation_background': poem.creationBackground,
  };
}
