import 'package:flutter/material.dart';
import '../core/data/mock_data.dart';
import '../core/theme/app_colors.dart';
import '../models/poem_badge.dart';
import '../models/user_profile.dart';

/// S12 프로필 화면 (내 것 / 남의 것 겸용)
/// - 기획서 철학: '보여주는 선반'
/// - 팔로워 수, 총 공감 수, 순위, 공개한 대화 목록 배제 (서열화 방지)
/// - 닉네임, 누적일수, 받은 뱃지 선반 그리드
class S12ProfileScreen extends StatelessWidget {
  final UserProfile? profile;
  final bool isMe;

  const S12ProfileScreen({
    super.key,
    this.profile,
    this.isMe = false,
  });

  /// 내 프로필 바로가기 생성자
  factory S12ProfileScreen.myProfile() {
    return S12ProfileScreen(
      profile: MockData.myProfile,
      isMe: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = profile ?? MockData.myProfile;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          isMe ? '내 선반' : '${user.nickname}의 선반',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. 프로필 상단 헤더 (아바타 & 닉네임)
            Center(
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      user.nickname.characters.first,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentWine,
                        fontFamily: 'NanumMyeongjo',
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    user.nickname,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (isMe)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        '이메일 계정으로 연결됨',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // 2. 누적일수 카드 (홈 문구와 연계: "지금까지 N일 시를 읽었어요")
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.inputBackground,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.calendar_today_outlined,
                      size: 20,
                      color: AppColors.confirmedGreen,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '시를 읽은 날',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '지금까지 ${user.streakDays}일 시를 읽었어요',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 3. 받은 뱃지 선반 (F8 기록·보상 핵심)
            Row(
              children: [
                const Text(
                  '모은 시 뱃지',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${user.badges.length}개',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.accentWine,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              '끝까지 읽고 생각을 저장한 시마다 그 시를 닮은 뱃지가 남습니다.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),

            // 뱃지 선반 그리드
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: user.badges.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.85,
              ),
              itemBuilder: (context, index) {
                final badge = user.badges[index];
                return _BadgeItem(badge: badge);
              },
            ),

            if (user.badges.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 40),
                alignment: Alignment.center,
                child: const Text(
                  '아직 모은 뱃지가 없습니다.\n시를 읽고 해석을 저장해 보세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ),

            const SizedBox(height: 32),

            // 내 프로필일 경우의 보조 안내
            if (isMe) ...[
              const Divider(color: AppColors.border),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  '프로필은 당신의 생각을 모아두는 조용한 선반입니다.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }
}

class _BadgeItem extends StatelessWidget {
  final PoemBadge badge;

  const _BadgeItem({required this.badge});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 뱃지 상징 아이콘 (심볼/이미지)
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.inputBackground,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.accentWine.withValues(alpha: 0.2),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              badge.iconSymbol,
              style: const TextStyle(fontSize: 22),
            ),
          ),
          const SizedBox(height: 10),
          // 뱃지 이름
          Text(
            badge.name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          // 시 제목
          Text(
            badge.poemTitle,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
