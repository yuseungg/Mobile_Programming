// 주인: A — 모델에게 보내는 툴 목록과 실행 (기획서 6장 「툴」)
// 이름은 기획서 그대로 snake_case, Dart 함수는 lowerCamelCase (네이밍규칙 2장).
// compare_with_experts · get_poem_context의 본체는 D가 만든다 (lib/compare/compare_tools.dart).
// 툴 권한은 앱 상태에 따라 바뀐다 — 저장 전에는 그 둘을 보내지 않고, 불러도 거부한다.
import '../../compare/compare_tools.dart';
import '../../data/models/expert_interpretation.dart';
import '../../data/models/poem.dart';
import 'poem_text.dart';
import 'search_poem_lines.dart';
import 'verify_quote.dart';

/// 툴 한 번을 실행한 결과
class ToolResult {
  const ToolResult(this.output, {this.quoteCheck, this.matches});

  final Map<String, Object?> output; // 모델에게 돌려줄 JSON
  final QuoteCheck? quoteCheck; // verify_quote였다면 — 근거 행 계산에 쓴다
  final List<LineMatch>? matches; // search_poem_lines였다면
}

class AgentTools {
  const AgentTools({
    required this.poem,
    required this.isSaved,
    this.myEvidenceLines = const [],
    this.myInterpretation = '',
    this.experts = const [],
  });

  final Poem poem;
  final bool isSaved; // 그 시의 해석을 저장했는가

  // 저장 뒤에만 쓰는 것 — compare_with_experts의 재료
  final List<int> myEvidenceLines; // 저장한 해석의 근거 행 (1부터)
  final String myInterpretation; // 저장한 해석
  final List<ExpertInterpretation> experts; // 그 시의 전문가 해석. 아직 없으면 빈 목록

  static const verifyQuoteName = 'verify_quote';
  static const searchPoemLinesName = 'search_poem_lines';
  static const compareWithExpertsName = 'compare_with_experts';
  static const getPoemContextName = 'get_poem_context';

  /// 모델에게 보내는 툴 정의 (OpenAI 형식). 저장 전에는 A의 두 툴만, 저장 뒤에는 넷 다.
  List<Map<String, Object?>> get definitions => [
        ..._alwaysDefinitions,
        if (isSaved) ..._afterSaveDefinitions,
      ];

  static const _alwaysDefinitions = [
        {
          'type': 'function',
          'function': {
            'name': verifyQuoteName,
            'description': '구절이 시 원문에 그대로 있는지 확인한다. '
                '사용자가 근거로 든 구절이나 네가 언급하려는 구절은 반드시 먼저 이것으로 확인한다. '
                '원문에 있으면 행 번호(1부터)를, 없으면 found=false를 돌려준다.',
            'parameters': {
              'type': 'object',
              'properties': {
                'quote': {'type': 'string', 'description': '확인할 구절 (따옴표 없이)'},
              },
              'required': ['quote'],
            },
          },
        },
        {
          'type': 'function',
          'function': {
            'name': searchPoemLinesName,
            'description': '시 안에서 낱말을 찾아, 그 낱말이 나오는 행 번호(1부터)와 행을 돌려준다.',
            'parameters': {
              'type': 'object',
              'properties': {
                'word': {'type': 'string', 'description': '찾을 낱말'},
              },
              'required': ['word'],
            },
          },
        },
      ];

  static const _afterSaveDefinitions = [
    {
      'type': 'function',
      'function': {
        'name': compareWithExpertsName,
        'description': '사용자가 저장한 해석과 전문가 해석 각각의 관계를 돌려준다. '
            'relation은 앱이 근거 행으로 정한 것이다 — sameLines(같은 곳을 봤다), '
            'partialOverlap(같은 줄에서 출발했다), differentLines(다른 행을 중심으로 읽었다). '
            '사용자가 전문가 해석이나 다른 읽기를 궁금해할 때 부른다.',
        'parameters': {'type': 'object', 'properties': <String, Object?>{}},
      },
    },
    {
      'type': 'function',
      'function': {
        'name': getPoemContextName,
        'description': '시의 창작 배경(사실만)을 돌려준다. '
            '사용자가 시가 쓰인 때나 배경을 궁금해할 때 부른다.',
        'parameters': {'type': 'object', 'properties': <String, Object?>{}},
      },
    },
  ];

  ToolResult run(String name, Map<String, Object?> arguments) {
    switch (name) {
      case verifyQuoteName:
        final check = verifyQuote(poem, '${arguments['quote'] ?? ''}');
        return ToolResult(check.toJson(), quoteCheck: check);
      case searchPoemLinesName:
        final word = '${arguments['word'] ?? ''}';
        final matches = searchPoemLines(poem, word);
        return ToolResult(
          {
            'word': normalizeQuote(word),
            'matches': [for (final match in matches) match.toJson()],
          },
          matches: matches,
        );
      // 「먼저 쓰고, 나중에 본다」를 프롬프트가 아니라 코드로 막는다.
      // 저장 전에는 정의를 보내지 않지만, 모델이 이름을 지어내 불러도 여기서 거부한다.
      case compareWithExpertsName:
        if (!isSaved) return _lockedResult;
        return ToolResult(compareWithExperts(
          myEvidenceLines: myEvidenceLines,
          myInterpretation: myInterpretation,
          experts: experts,
        ));
      case getPoemContextName:
        if (!isSaved) return _lockedResult;
        return ToolResult(getPoemContext(poem: poem));
      default:
        return ToolResult({'error': '없는 툴이다: $name'});
    }
  }

  static const _lockedResult =
      ToolResult({'error': '해석을 저장한 뒤에만 쓸 수 있는 툴이다.'});
}
