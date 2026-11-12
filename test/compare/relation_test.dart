// 주인: D — lib/compare/relation.dart 단위 테스트
// 기준: docs/여백-기획서최종.md 4장 「전문가 해석과의 대조 규칙」 표

import 'package:flutter_test/flutter_test.dart';
import 'package:yeobaek/compare/relation.dart';
import 'package:yeobaek/data/fakes/fake_data.dart';
import 'package:yeobaek/data/models/expert_interpretation.dart';

/// 근거 행만 지정해 전문가 해석을 만든다. 라벨·입장·주장 문구는 관계 계산과 무관하다.
ExpertInterpretation expertWith(List<List<int>> claimLines) {
  return ExpertInterpretation(
    label: '전문가 해석 T',
    stance: '테스트용 입장',
    claims: [
      for (final lines in claimLines) Claim(lines: lines, point: '테스트용 주장'),
    ],
  );
}

void main() {
  group('expertLines — 주장 여러 개의 근거 행을 합친다', () {
    test('중복을 지우고 오름차순으로 정렬한다', () {
      final expert = expertWith([
        [7, 2],
        [6, 7, 8],
      ]);
      expect(expertLines(expert), [2, 6, 7, 8]);
    });

    test('주장이 없으면 빈 목록', () {
      expect(expertLines(expertWith([])), isEmpty);
    });
  });

  group('computeRelation — 기획서 4장 표', () {
    test('같은 행을 근거로 삼음 → sameLines', () {
      final expert = expertWith([
        [2],
        [6],
      ]);
      expect(computeRelation([2, 6], expert), Relation.sameLines);
    });

    test('순서와 중복은 무시한다', () {
      final expert = expertWith([
        [6, 2],
      ]);
      expect(computeRelation([6, 2, 6], expert), Relation.sameLines);
    });

    test('근거 행이 일부만 겹침 → partialOverlap', () {
      final expert = expertWith([
        [2, 6],
      ]);
      expect(computeRelation([6, 9], expert), Relation.partialOverlap);
    });

    test('내 근거가 전문가 근거의 부분집합이어도 partialOverlap', () {
      final expert = expertWith([
        [2],
        [6, 7, 8],
      ]);
      expect(computeRelation([6], expert), Relation.partialOverlap);
    });

    test('전문가 근거가 내 근거의 부분집합이어도 partialOverlap', () {
      final expert = expertWith([
        [6],
      ]);
      expect(computeRelation([2, 6, 7], expert), Relation.partialOverlap);
    });

    test('다른 행을 근거로 삼음 → differentLines', () {
      final expert = expertWith([
        [10],
      ]);
      expect(computeRelation([6], expert), Relation.differentLines);
    });
  });

  group('computeRelation — 근거가 없는 경우', () {
    test('내 근거가 없으면 differentLines', () {
      final expert = expertWith([
        [6],
      ]);
      expect(computeRelation([], expert), Relation.differentLines);
    });

    test('전문가 근거가 없으면 differentLines', () {
      expect(computeRelation([6], expertWith([])), Relation.differentLines);
    });

    test('둘 다 없으면 sameLines가 아니라 differentLines', () {
      expect(computeRelation([], expertWith([])), Relation.differentLines);
    });
  });

  group('수록된 데이터로 보는 회귀 — 서시', () {
    final myLines = FakeData.myReadings['seosi']!.evidenceLines;
    final experts = FakeData.expertInterpretations['seosi']!;

    test('내 근거는 전문가 A 근거의 일부만 겹친다', () {
      // 고치기 전에는 포함을 같음으로 봐서 sameLines("같은 곳을 봤어요")가 나왔다.
      expect(myLines, [6]);
      expect(expertLines(experts[0]), [2, 6, 7, 8]);
      expect(computeRelation(myLines, experts[0]), Relation.partialOverlap);
    });

    test('전문가 B와는 겹치는 행이 없다', () {
      expect(expertLines(experts[1]), [10]);
      expect(computeRelation(myLines, experts[1]), Relation.differentLines);
    });
  });
}
