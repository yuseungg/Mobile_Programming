// 주인: D — 모델 없이 요약을 채우는 구현 (기획서 9장 「오프라인·실패 처리」)
//
// 사실만 적는다. 대화 내용을 추측해 옮기지 않는다 — 남이 읽는 글이라,
// 쓰지 않은 말이 요약에 들어가면 안 된다. 그래서 첫 낱말과 질문 수만 쓴다.

import '../app/strings.dart';
import 'summary_writer.dart';

class FakeSummaryWriter implements SummaryWriter {
  const FakeSummaryWriter();

  @override
  Future<SummaryText> write(SummaryRequest request) async {
    return SummaryText(
      AppStrings.communitySummaryFallback(
        request.firstWord,
        request.questionCount,
      ),
      isFallback: true,
    );
  }
}
