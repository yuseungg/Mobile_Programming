// 툴 verify_quote · search_poem_lines (A), 저장 전후 툴 권한 — 기획서 6장
import 'package:flutter_test/flutter_test.dart';
import 'package:yeobaek/agent/tools/agent_tools.dart';
import 'package:yeobaek/agent/tools/search_poem_lines.dart';
import 'package:yeobaek/agent/tools/verify_quote.dart';
import 'package:yeobaek/data/fakes/fake_data.dart';
import 'package:yeobaek/data/models/expert_interpretation.dart';

void main() {
  final seosi = FakeData.poemById('seosi');

  group('verify_quote', () {
    test('원문에 없는 구절은 찾지 못한다 (시연 시나리오)', () {
      final check = verifyQuote(seosi, '별을 그리워하며');
      expect(check.isFound, isFalse);
      expect(check.toJson(), {'found': false, 'quote': '별을 그리워하며'});
    });

    test('있는 구절은 1부터 센 행 번호를 돌려준다', () {
      expect(verifyQuote(seosi, '모든 죽어가는 것을 사랑해야지').lineNos, [6]);
    });

    test('연 구분 빈 줄도 번호를 하나 차지한다 — 서시의 마지막 행은 10행', () {
      expect(verifyQuote(seosi, '오늘 밤에도 별이 바람에 스치운다').lineNos, [10]);
    });

    test('따옴표와 끝 문장부호는 떼고 찾는다', () {
      expect(verifyQuote(seosi, "'한 점 부끄럼이 없기를'").lineNos, [2]);
      expect(verifyQuote(seosi, '걸어가야겠다.').lineNos, [8]);
    });

    test('행을 넘어가는 구절도 찾는다', () {
      expect(verifyQuote(seosi, '주어진 길을 걸어가야겠다').lineNos, [7, 8]);
    });

    test('빈 구절은 찾지 못한다', () {
      expect(verifyQuote(seosi, " '' ").isFound, isFalse);
    });
  });

  group('search_poem_lines', () {
    test("'별'은 5행과 10행에 나온다", () {
      final lineNos = [for (final match in searchPoemLines(seosi, '별')) match.lineNo];
      expect(lineNos, [5, 10]);
    });

    test('행 번호와 행을 함께 돌려준다', () {
      expect(
        searchPoemLines(seosi, '바람').first.toJson(),
        {'lineNo': 3, 'line': '잎새에 이는 바람에도'},
      );
    });

    test('빈 낱말은 아무것도 찾지 않는다', () {
      expect(searchPoemLines(seosi, '  '), isEmpty);
    });
  });

  // 툴 권한 — 「먼저 쓰고, 나중에 본다」를 코드가 막는다 (기획서 6장)
  group('저장 전후 툴 권한', () {
    List<String> namesOf(AgentTools tools) => [
          for (final definition in tools.definitions)
            (definition['function'] as Map)['name'] as String,
        ];
    final experts = FakeData.expertInterpretations['seosi']!;

    test('저장 전에는 A의 두 툴만 보낸다', () {
      final tools = AgentTools(poem: seosi, isSaved: false);
      expect(namesOf(tools), ['verify_quote', 'search_poem_lines']);
    });

    test('저장 전에 D의 툴을 불러도 거부한다', () {
      final tools = AgentTools(poem: seosi, isSaved: false, experts: experts);
      for (final name in ['compare_with_experts', 'get_poem_context']) {
        expect(tools.run(name, const {}).output,
            {'error': '해석을 저장한 뒤에만 쓸 수 있는 툴이다.'});
      }
    });

    test('저장 뒤에는 넷 다 보낸다', () {
      final tools = AgentTools(poem: seosi, isSaved: true);
      expect(namesOf(tools), [
        'verify_quote',
        'search_poem_lines',
        'compare_with_experts',
        'get_poem_context',
      ]);
    });

    test('저장 뒤 compare_with_experts는 저장한 근거 행으로 관계를 계산한다', () {
      // 서시 전문가 B의 근거는 10행 하나 → 10행만 근거로 들었으면 같은 곳
      final tools = AgentTools(
        poem: seosi,
        isSaved: true,
        myEvidenceLines: const [10],
        myInterpretation: '밤은 그대로 온다',
        experts: experts,
      );
      final output = tools.run('compare_with_experts', const {}).output;
      expect((output['mine'] as Map)['lines'], [10]);
      final relations = [
        for (final expert in output['experts'] as List)
          (expert as Map)['relation'],
      ];
      expect(relations, [Relation.differentLines.name, Relation.sameLines.name]);
    });

    test('저장 뒤 get_poem_context는 창작 배경을 돌려준다', () {
      final tools = AgentTools(poem: seosi, isSaved: true);
      final output = tools.run('get_poem_context', const {}).output;
      expect(output['creation_background'], seosi.creationBackground);
    });
  });
}
