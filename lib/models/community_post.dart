/// 커뮤니티 공개 대화 글 모델
class CommunityPost {
  final String id;
  final String authorUid;
  final String authorNickname; // 예: '조용한 별'
  final String poemId;
  final String poemTitle;
  final String firstWord; // 떠오른 낱말
  final String aiSummary; // AI 대화 요약
  final List<int> groundedLines; // 근거 구절 행 번호
  final String finalInterpretation; // 최종 해석
  int empathyCount; // 공감 수 (정렬에 사용되지 않음)
  bool isEmpathized; // 현재 사용자의 공감 여부
  final DateTime createdAt;

  CommunityPost({
    required this.id,
    required this.authorUid,
    required this.authorNickname,
    required this.poemId,
    required this.poemTitle,
    required this.firstWord,
    required this.aiSummary,
    required this.groundedLines,
    required this.finalInterpretation,
    required this.empathyCount,
    this.isEmpathized = false,
    required this.createdAt,
  });
}
