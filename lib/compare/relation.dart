// 주인: D — 내 해석과 전문가 해석의 관계 계산 (기획서 4장)
// D의 part-d `ExpertReading.calculateRelationship()`을 옮긴 것. 문구는 화면에서 AppStrings로 바꾼다.
// 2단계에서 compare_with_experts 툴이 이 함수를 쓴다.

import '../data/models/expert_interpretation.dart';

/// 전문가 해석의 근거 행 전체 (오름차순)
List<int> expertLines(ExpertInterpretation expert) {
  final lines = <int>{};
  for (final claim in expert.claims) {
    lines.addAll(claim.lines);
  }
  return lines.toList()..sort();
}

/// 근거 행 겹침으로 관계를 정한다.
/// - 겹치지 않음 → differentLines
/// - 한쪽이 다른 쪽을 모두 포함 → sameLines
/// - 일부만 겹침 → partialOverlap
Relation computeRelation(List<int> myLines, ExpertInterpretation expert) {
  final mine = myLines.toSet();
  final theirs = expertLines(expert).toSet();
  final overlap = mine.intersection(theirs);

  if (overlap.isEmpty) return Relation.differentLines;
  if (overlap.length == theirs.length || overlap.length == mine.length) {
    return Relation.sameLines;
  }
  return Relation.partialOverlap;
}
