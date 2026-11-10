// 주인: D — 모델 없이 비교 문장을 채우는 구현 (기획서 9장 「오프라인·실패 처리」)
//
// 쓰는 순서:
//  1. 미리 쓴 문장이 있으면 그것 (assets 또는 가짜 데이터)
//  2. 없으면 관계 한 줄
//
// 둘 다 모델을 부르지 않으므로 키가 없어도, 네트워크가 끊겨도 돈다.
// 시연 중 사고에 대한 보험이다.
//
// 둘 다 「공통점부터 말하고, 내가 놓친 것을 가리키지 않는다」를 지킨다
// (기획서 4장). 전문가만 근거로 삼은 행은 문장에 넣지 않는다.

import '../app/strings.dart';
import '../compare/relation.dart';
import '../data/models/expert_interpretation.dart';
import 'comparison_writer.dart';

class FakeComparisonWriter implements ComparisonWriter {
  const FakeComparisonWriter({this.prewritten = const {}});

  /// poemId → 전문가 해석과 같은 순서의 미리 쓴 문장
  final Map<String, List<String>> prewritten;

  @override
  Future<ComparisonText> write(ComparisonRequest request) async {
    final texts = prewritten[request.poemId];
    if (texts != null && request.expertIndex < texts.length) {
      final text = texts[request.expertIndex];
      if (text.trim().isNotEmpty) {
        return ComparisonText(text, isFallback: true);
      }
    }
    return ComparisonText(relationSentence(request), isFallback: true);
  }
}

/// 관계 한 줄. 모델도 미리 쓴 문장도 없을 때 마지막으로 채우는 것.
String relationSentence(ComparisonRequest request) {
  final mine = request.myEvidenceLines.toSet();
  final shared = (mine.intersection(expertLines(request.expert).toSet()).toList()
    ..sort());

  return switch (request.relation) {
    Relation.sameLines => AppStrings.comparisonFallbackSameLines(shared),
    Relation.partialOverlap =>
      AppStrings.comparisonFallbackPartialOverlap(shared),
    Relation.differentLines => AppStrings.comparisonFallbackDifferentLines,
  };
}
