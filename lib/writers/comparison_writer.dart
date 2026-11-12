// 주인: D — 비교 문장 쓰기 (기획서 4장 「대조」, 요건 (a) 둘째 화면)
//
// 관계는 코드가 정하고(lib/compare/relation.dart), 모델은 비교 문장만 쓴다.
// 그래서 이 인터페이스는 관계를 **입력으로 받는다.** 모델이 관계를 다시
// 판단하는 일이 없어야 한다.
//
// 모델 호출이 실패해도 화면은 빈 칸이 되면 안 된다. 그래서 돌려주는 값에
// isFallback을 달아, 미리 쓴 문장이나 관계 한 줄로 대신했음을 화면이 안다.
//
// A의 OpenRouterClient를 쓰는 구현체는 PR #5가 병합된 뒤에 붙인다.
// 그때 추가되는 것은 이 인터페이스를 구현하는 클래스 하나뿐이다.

import '../data/models/expert_interpretation.dart';

/// 비교 문장 한 개를 쓰기 위해 필요한 것
class ComparisonRequest {
  const ComparisonRequest({
    required this.poemId,
    required this.myInterpretation,
    required this.myEvidenceLines,
    required this.expert,
    required this.relation,
    required this.expertIndex,
  });

  final String poemId;
  final String myInterpretation;
  final List<int> myEvidenceLines;
  final ExpertInterpretation expert;

  /// 코드가 이미 계산한 관계. 모델이 다시 판단하지 않는다.
  final Relation relation;

  /// 전문가 해석의 순서 — 미리 쓴 문장이 같은 순서로 들어 있다
  final int expertIndex;
}

/// 쓰인 비교 문장
class ComparisonText {
  const ComparisonText(this.text, {this.isFallback = false});

  final String text;

  /// 모델이 쓴 것이 아니라 대신 채운 것인가
  final bool isFallback;
}

abstract interface class ComparisonWriter {
  /// 비교 문장 하나를 쓴다. 실패해도 예외를 던지지 않고 대신 채운다 —
  /// 대조 화면이 빈 칸으로 남는 것이 가장 나쁘다.
  Future<ComparisonText> write(ComparisonRequest request);
}
