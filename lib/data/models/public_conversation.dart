// 주인: C · 용어: docs/여백-네이밍규칙.md 2장 「커뮤니티」, 5장 Firestore

class PublicConversation {
  const PublicConversation({
    required this.conversationId,
    required this.userId,
    required this.poemId,
    required this.firstWord,
    required this.summary,
    required this.interpretation,
    required this.empathyCount,
  });

  final String conversationId;
  final String userId; // 작성자 — 화면에는 닉네임으로 표시
  final String poemId;
  final String firstWord;
  final String summary; // AI가 뽑은 대화 요약
  final String interpretation; // 최종 해석
  final int empathyCount; // 정렬·순위에 쓰지 않는다
}
