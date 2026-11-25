// 주인: D — 모델 없이 비교 문장을 채우는 구현 (기획서 9장 「오프라인·실패 처리」)
//
// 쓰는 것:
//  1. 관계 한 줄 — 내 근거 행과 전문가 근거 행을 그 자리에서 비교해 만든다
//  2. 미리 쓴 문장이 있으면 그 뒤에 붙인다 (assets 또는 가짜 데이터)
//
// 모델을 부르지 않으므로 키가 없어도, 네트워크가 끊겨도 돈다.
// 시연 중 사고에 대한 보험이다.
//
// 「공통점부터 말하고, 내가 놓친 것을 가리키지 않는다」를 지킨다 (기획서 4장).
// 전문가만 근거로 삼은 행은 문장에 넣지 않는다.
//
// ── 미리 쓴 문장이 내 해석을 말하면 안 되는 이유 ──
// 전에는 미리 쓴 문장이 있으면 그것**만** 내보냈다. 그 문장은 시연용 해석에
// 맞춰 쓰여 있어서 「내 해석은 그 다짐을 자기를 견디는 말로 읽었고」처럼
// 사람이 쓰지도 않은 내용을 단정했다. 모델이 막히면(무료 한도 429) 누구에게나
// 그 문장이 나온다 — 태블릿 점검에서 실제로 나왔다.
//
// 그래서 **내 해석에 대한 말은 관계 한 줄만 한다.** 그 한 줄은 근거 행에서
// 그 자리에 계산하므로 언제나 맞다. 미리 쓴 문장은 **전문가 해석만** 설명하고,
// 내 것을 가리키지 않는다. 새 문장을 넣을 때도 이 규칙을 지킨다.

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
    final relation = relationSentence(request);
    final note = _noteFor(request);
    return ComparisonText(
      note == null ? relation : '$relation $note',
      isFallback: true,
    );
  }

  /// 전문가 해석을 설명하는, 미리 쓴 한 줄. 없으면 null.
  String? _noteFor(ComparisonRequest request) {
    final texts = prewritten[request.poemId];
    if (texts == null || request.expertIndex >= texts.length) return null;
    final text = texts[request.expertIndex].trim();
    return text.isEmpty ? null : text;
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
