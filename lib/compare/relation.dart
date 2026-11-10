// 주인: D — 내 해석과 전문가 해석의 관계 계산 (기획서 4장)
// D의 part-d `ExpertReading.calculateRelationship()`을 옮긴 것. 문구는 화면에서 AppStrings로 바꾼다.
// 2단계에서 compare_with_experts 툴이 이 함수를 쓴다.

import '../data/models/expert_interpretation.dart';

/// 전문가 해석의 근거 행 전체 (중복 제거, 오름차순)
List<int> expertLines(ExpertInterpretation expert) {
  final lines = <int>{};
  for (final claim in expert.claims) {
    lines.addAll(claim.lines);
  }
  return lines.toList()..sort();
}

/// 근거 행 겹침으로 관계를 정한다 (기획서 4장 표).
/// - 같은 행을 근거로 삼음 (집합이 같음) → sameLines
/// - 근거 행이 일부만 겹침 → partialOverlap
/// - 다른 행을 근거로 삼음 (겹치지 않음) → differentLines
///
/// 한쪽이 다른 쪽을 포함하는 것은 "같은 행"이 아니라 "일부만 겹침"이다.
/// 내 근거는 보통 1~2행이고 전문가는 4행이라, 포함을 같음으로 보면
/// partialOverlap이 거의 나오지 않고 3상태가 2상태로 붕괴한다.
///
/// 어느 한쪽이라도 근거가 없으면 겹침을 따질 수 없으므로 differentLines로 둔다.
/// 둘 다 비었을 때 "같은 곳을 봤어요"가 나오면 안 된다.
Relation computeRelation(List<int> myLines, ExpertInterpretation expert) {
  final mine = myLines.toSet();
  final theirs = expertLines(expert).toSet();

  if (mine.isEmpty || theirs.isEmpty) return Relation.differentLines;

  final overlap = mine.intersection(theirs);
  if (overlap.isEmpty) return Relation.differentLines;
  if (overlap.length == mine.length && overlap.length == theirs.length) {
    return Relation.sameLines;
  }
  return Relation.partialOverlap;
}
