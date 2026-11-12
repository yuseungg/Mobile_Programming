// 주인: D — lib/compare/compare_tools.dart 단위 테스트
// 기준: docs/여백-기획서최종.md 4장(관계) · 6장(툴) · 7장(창작 배경은 사실만)

import 'package:flutter_test/flutter_test.dart';
import 'package:yeobaek/compare/compare_tools.dart';
import 'package:yeobaek/data/fakes/fake_data.dart';
import 'package:yeobaek/data/models/expert_interpretation.dart';

void main() {
  final experts = FakeData.expertInterpretations['seosi']!;
  final reading = FakeData.myReadings['seosi']!;

  group('compareWithExperts', () {
    test('전문가 수만큼 돌려주고 라벨·입장을 그대로 싣는다', () {
      final out = compareWithExperts(
        myEvidenceLines: reading.evidenceLines,
        myInterpretation: reading.interpretation,
        experts: experts,
      );
      final got = out['experts']! as List;
      expect(got, hasLength(2));
      expect((got[0] as Map)['label'], '전문가 해석 A');
      expect((got[1] as Map)['stance'], '시대 앞의 무력감으로 읽는 입장');
    });

    test('관계는 코드가 계산한 Relation 이름으로 나간다', () {
      final out = compareWithExperts(
        myEvidenceLines: reading.evidenceLines,
        myInterpretation: reading.interpretation,
        experts: experts,
      );
      final got = out['experts']! as List;
      expect((got[0] as Map)['relation'], 'partialOverlap');
      expect((got[1] as Map)['relation'], 'differentLines');
    });

    test('겹친 행만 싣고, 전문가만 본 행은 싣지 않는다', () {
      // 기획서 4장: "전문가는 이 줄도 봤다"는 문장을 금지한다.
      // 그 재료를 미리 계산해 넘기지 않는다.
      final out = compareWithExperts(
        myEvidenceLines: const [6],
        myInterpretation: '내 해석',
        experts: experts,
      );
      final first = (out['experts']! as List).first as Map;
      expect(first['shared_lines'], [6]);
      expect(first.containsKey('only_in_theirs'), isFalse);
      expect(first.keys, isNot(contains('missed_lines')));
    });

    test('내 근거는 중복을 지우고 정렬해서 싣는다', () {
      final out = compareWithExperts(
        myEvidenceLines: const [7, 2, 7],
        myInterpretation: '내 해석',
        experts: experts,
      );
      expect((out['mine']! as Map)['lines'], [2, 7]);
      expect((out['mine']! as Map)['interpretation'], '내 해석');
    });

    test('주장의 근거 행과 핵심 문장을 그대로 싣는다', () {
      final out = compareWithExperts(
        myEvidenceLines: const [6],
        myInterpretation: '내 해석',
        experts: experts,
      );
      final claims = ((out['experts']! as List).first as Map)['claims']! as List;
      expect(claims, hasLength(2));
      expect((claims[1] as Map)['lines'], [6, 7, 8]);
      expect((claims[1] as Map)['point'], '괴로움을 통과한 뒤에 나온 다짐이다');
    });

    test('전문가 목록이 비면 experts도 빈 목록', () {
      final out = compareWithExperts(
        myEvidenceLines: const [6],
        myInterpretation: '내 해석',
        experts: const <ExpertInterpretation>[],
      );
      expect(out['experts'], isEmpty);
    });
  });

  group('getPoemContext', () {
    test('창작 배경과 서지 사실만 싣는다', () {
      final poem = FakeData.poemById('seosi');
      final out = getPoemContext(poem: poem);
      expect(out['poem'], 'seosi');
      expect(out['title'], poem.title);
      expect(out['author'], poem.author);
      expect(out['year'], poem.year);
      expect(out['creation_background'], poem.creationBackground);
    });

    test('시 본문과 해석은 싣지 않는다', () {
      // 기획서 7장: 창작 배경은 사실만, 해석과 별도 필드.
      final out = getPoemContext(poem: FakeData.poemById('seosi'));
      expect(out.keys, isNot(contains('lines')));
      expect(out.keys, isNot(contains('readings')));
      expect(out.keys, isNot(contains('interpretation')));
    });
  });
}
