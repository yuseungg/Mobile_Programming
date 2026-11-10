// 주인: D — 비교 문장 폴백 (기획서 4장 · 9장 「오프라인·실패 처리」)
import 'package:flutter_test/flutter_test.dart';
import 'package:yeobaek/data/models/expert_interpretation.dart';
import 'package:yeobaek/writers/comparison_writer.dart';
import 'package:yeobaek/writers/fake_comparison_writer.dart';

ExpertInterpretation expertWith(List<List<int>> claimLines) =>
    ExpertInterpretation(
      label: '전문가 해석 T',
      stance: '입장',
      claims: [
        for (final lines in claimLines) Claim(lines: lines, point: '주장'),
      ],
    );

ComparisonRequest request({
  List<int> myLines = const [6],
  List<List<int>> expertLines = const [[6]],
  Relation relation = Relation.sameLines,
  int index = 0,
  String poemId = 'seosi',
}) =>
    ComparisonRequest(
      poemId: poemId,
      myInterpretation: '내 해석',
      myEvidenceLines: myLines,
      expert: expertWith(expertLines),
      relation: relation,
      expertIndex: index,
    );

void main() {
  group('미리 쓴 문장이 있으면 그것을 쓴다', () {
    test('전문가 순서와 같은 자리의 문장', () async {
      const writer = FakeComparisonWriter(prewritten: {
        'seosi': ['첫째 문장', '둘째 문장'],
      });
      expect((await writer.write(request(index: 0))).text, '첫째 문장');
      expect((await writer.write(request(index: 1))).text, '둘째 문장');
    });

    test('미리 쓴 것도 폴백으로 표시된다 — 모델이 쓴 게 아니다', () async {
      const writer = FakeComparisonWriter(prewritten: {
        'seosi': ['첫째 문장'],
      });
      expect((await writer.write(request())).isFallback, isTrue);
    });

    test('자리가 비어 있으면 관계 한 줄로 넘어간다', () async {
      const writer = FakeComparisonWriter(prewritten: {
        'seosi': ['   '],
      });
      final text = (await writer.write(request())).text;
      expect(text, isNot('   '));
      expect(text, contains('6행'));
    });

    test('문장 수가 전문가 수보다 적어도 깨지지 않는다', () async {
      const writer = FakeComparisonWriter(prewritten: {
        'seosi': ['하나뿐'],
      });
      expect((await writer.write(request(index: 5))).text, isNotEmpty);
    });

    test('다른 시의 문장을 가져오지 않는다', () async {
      const writer = FakeComparisonWriter(prewritten: {
        'jindallae': ['진달래 문장'],
      });
      expect((await writer.write(request())).text, isNot('진달래 문장'));
    });
  });

  group('관계 한 줄 — 공통점부터, 놓친 것은 가리키지 않는다', () {
    const writer = FakeComparisonWriter();

    test('같은 행이면 그 행을 말한다', () async {
      final text = (await writer.write(request(
        myLines: const [2, 6],
        expertLines: const [[2, 6]],
        relation: Relation.sameLines,
      ))).text;
      expect(text, contains('2, 6행'));
    });

    test('일부만 겹치면 겹친 행만 말한다', () async {
      final text = (await writer.write(request(
        myLines: const [6],
        expertLines: const [[2, 6, 7, 8]],
        relation: Relation.partialOverlap,
      ))).text;
      expect(text, contains('6행'));
      // 전문가만 본 2·7·8행은 문장에 나오지 않는다 (기획서 4장)
      expect(text, isNot(contains('2')));
      expect(text, isNot(contains('7')));
      expect(text, isNot(contains('8')));
    });

    test('겹치지 않으면 행 번호를 말하지 않는다', () async {
      final text = (await writer.write(request(
        myLines: const [6],
        expertLines: const [[10]],
        relation: Relation.differentLines,
      ))).text;
      expect(text, isNot(contains('10')));
      expect(text, isNot(contains('6')));
      expect(text, contains('다른 줄'));
    });

    test('항상 비어 있지 않다 — 대조 화면이 빈 칸이 되면 안 된다', () async {
      for (final relation in Relation.values) {
        final result = await writer.write(request(relation: relation));
        expect(result.text.trim(), isNotEmpty, reason: '$relation');
        expect(result.isFallback, isTrue);
      }
    });
  });
}
