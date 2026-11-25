// 주인: C · 용어: docs/여백-네이밍규칙.md 2장 「커뮤니티」, 5장 Firestore

import 'chat_message.dart';

class PublicConversation {
  const PublicConversation({
    required this.conversationId,
    required this.userId,
    required this.poemId,
    required this.firstWord,
    required this.summaryKo,
    required this.summaryEn,
    required this.interpretation,
    required this.empathyCount,
    this.evidenceLines = const [],
    this.conversation = const [],
    required this.createdAt,
  });

  final String conversationId;
  final String userId; // 작성자 — 화면에는 닉네임으로 표시
  final String poemId;
  final String firstWord;

  // AI가 뽑은 대화 요약. 저장할 때 한국어 · 영어 두 벌을 함께 쓴다 —
  // 보는 사람이 고른 KR / EN에 맞춰 [summaryIn]으로 고른다.
  final String summaryKo;
  final String summaryEn;

  final String interpretation; // 최종 해석
  final int empathyCount; // 정렬·순위에 쓰지 않는다
  final List<int> evidenceLines; // 대화에서 확인된 근거 행 (1부터) — 기획서 F7 "근거 구절과 함께 표시"

  // 공개할 때 복사한 대화 전체 (AI 질문 + 사용자 답, 처음부터 끝까지) — S09 「3. 대화 기록」.
  // 개인 기록(users/{uid}/readings)의 대화를 S11에서 지워도 이것은 남는다.
  final List<ChatMessage> conversation;

  final DateTime createdAt; // 대화 목록 최신순 정렬용 (기획서 9장 2번)

  /// 보는 사람의 언어에 맞는 요약
  String summaryIn({required bool english}) => english ? summaryEn : summaryKo;

  PublicConversation copyWith({String? conversationId, int? empathyCount}) =>
      PublicConversation(
        conversationId: conversationId ?? this.conversationId,
        userId: userId,
        poemId: poemId,
        firstWord: firstWord,
        summaryKo: summaryKo,
        summaryEn: summaryEn,
        interpretation: interpretation,
        empathyCount: empathyCount ?? this.empathyCount,
        evidenceLines: evidenceLines,
        conversation: conversation,
        createdAt: createdAt,
      );
}
