// 주인: D — 공개 대화의 요약 쓰기 (기획서 F7 「공개 대화」)
//
// 요약은 저장할 때 한 번 쓰이고 공개 대화 문서에 담긴다. 화면이 열릴
// 때마다 모델을 부르지 않는다 — 남의 대화를 볼 때 비용이 들면 안 된다.
//
// 호출 지점은 S06 저장 화면이다 (PR #8 리뷰에서 B와 확인). 저장 버튼을 누르면
// S06이 여기서 요약을 만들어 saveInterpretation(summary:)로 넘기고, 저장소가
// 그것을 공개 대화 문서에 담는다 — 저장소는 글을 쓰지 않고 받은 것만 넣는다.
// 공개가 꺼져 있으면 요약이 필요 없으므로 null을 넘긴다.
//
// 요약은 한국어 · 영어 두 벌을 쓴다. 보는 사람이 KR / EN 중 무엇을 고르든 그 말로
// 읽게 하려는 것이다. 그래서 언어는 화면 언어가 아니라 요청([SummaryRequest.language])이 정한다.
//
// 요약 때문에 저장이 실패하면 안 되므로 write는 예외를 던지지 않는다 (기획서 9장).

import '../app/language.dart';
import '../data/models/chat_message.dart';

class SummaryRequest {
  const SummaryRequest({
    required this.poemId,
    required this.firstWord,
    required this.conversation,
    required this.interpretation,
    required this.language,
  });

  final String poemId;
  final String firstWord;
  final List<ChatMessage> conversation;

  /// 사용자가 쓴 최종 해석 — 요약이 해석과 어긋나지 않게 함께 넘긴다
  final String interpretation;

  /// 요약을 쓸 언어. 지시문 · 검사 · 대체 문장이 모두 이것을 따른다.
  final AppLanguage language;

  bool get isEnglish => language == AppLanguage.en;

  /// AI가 던진 질문 수 — 폴백 문장이 쓰는 유일한 숫자
  int get questionCount =>
      conversation.where((message) => !message.isUser).length;
}

class SummaryText {
  const SummaryText(this.text, {this.isFallback = false});

  final String text;
  final bool isFallback;
}

abstract interface class SummaryWriter {
  /// 요약 하나를 쓴다. 실패해도 예외를 던지지 않는다 — 저장은 잠금 해제와
  /// 뱃지 획득의 분기점이라, 요약 때문에 저장이 실패하면 안 된다 (기획서 9장).
  Future<SummaryText> write(SummaryRequest request);
}
