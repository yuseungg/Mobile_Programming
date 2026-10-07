import 'poem_badge.dart';

/// 사용자 프로필 모델 (S12 내 프로필 / 남의 프로필 공용)
class UserProfile {
  final String uid;
  final String nickname; // 무작위 닉네임 (형용사 + 시 명사)
  final int streakDays; // 누적일수 (연속 출석이 아닌 누적 일수)
  final List<PoemBadge> badges; // 획득한 뱃지 목록 (보여주는 선반)

  const UserProfile({
    required this.uid,
    required this.nickname,
    required this.streakDays,
    required this.badges,
  });
}
