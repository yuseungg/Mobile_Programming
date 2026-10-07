// 주인: C · 용어: docs/여백-네이밍규칙.md 2장 「사용자 · 보상」
// 프로필에 없는 것: 팔로워 수, 총 공감 수, 순위, 공개한 대화 목록

class UserProfile {
  const UserProfile({
    required this.userId,
    required this.nickname,
    required this.totalReadingDays,
    required this.lastCountedDate,
    required this.badgeIds,
  });

  final String userId; // Firebase uid
  final String nickname; // 앱이 무작위로 정함
  final int totalReadingDays; // 누적일수 — 연속이 아님
  final DateTime lastCountedDate; // 서버 시간 기준
  final List<String> badgeIds; // 뱃지 id = poemId
}
