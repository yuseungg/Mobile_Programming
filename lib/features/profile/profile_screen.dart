// S12 프로필 — 주인: D
// D의 part-d `S12ProfileScreen`을 이름만 맞춰 옮겼다 (docs/여백-이름대조표.md).
// - '보여주는 선반': 닉네임, 누적일수, 받은 뱃지
// - 팔로워 수, 총 공감 수, 순위, 공개한 대화 목록은 없다 (기획서 F8)
// - 내 것 · 남의 것 겸용. 내 것인지는 userId로 판단
// - 뱃지는 문구 없이 이미지만 (기획서 F8) — part-d의 뱃지 이름(별 · 꽃 · 고양이) 글자는 뺐다
import 'package:flutter/material.dart';

import '../../app/strings.dart';
import '../community/locked_notice.dart';
import '../../app/theme.dart';
import '../../data/models/user_profile.dart';
import '../../ports/repository_reading_source.dart';
import '../../ports/reading_source.dart';
import 'badge_image.dart';

/// 화면 한 번에 필요한 것 — 읽기를 한 곳에 모아 둔다
class _ProfileData {
  const _ProfileData({
    required this.profile,
    required this.isMe,
    required this.badgeTitles,
  });

  final UserProfile profile;
  final bool isMe;
  final Map<String, String> badgeTitles; // 뱃지 id(=poemId) → 시 제목
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.userId,
    this.source = const RepositoryReadingSource(),
  });

  final String userId;
  final ReadingSource source;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final Future<_ProfileData> _data = _load();

  Future<_ProfileData> _load() async {
    final source = widget.source;
    final profile = await source.profileById(widget.userId);
    final badgeTitles = <String, String>{};
    for (final badgeId in profile.badgeIds) {
      badgeTitles[badgeId] = (await source.poemById(badgeId)).title;
    }
    return _ProfileData(
      profile: profile,
      isMe: profile.userId == source.myUserId,
      badgeTitles: badgeTitles,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ProfileData>(
      future: _data,
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (snapshot.hasError) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: UnavailableNotice()),
          );
        }
        if (data == null) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return _content(context, data);
      },
    );
  }

  Widget _content(BuildContext context, _ProfileData data) {
    final profile = data.profile;
    final isMe = data.isMe;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          isMe
              ? AppStrings.profileMyTitle
              : AppStrings.profileOtherTitle(profile.nickname),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. 프로필 상단 (아바타 & 닉네임)
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
                          color: AppColors.text.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      profile.nickname.characters.first,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent,
                        fontFamily: AppFonts.myeongjo,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    profile.nickname,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  if (isMe)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        AppStrings.profileEmailLinked,
                        style:
                            AppText.caption,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // 2. 누적일수 카드
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
                      color: AppColors.input,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.calendar_today_outlined,
                      size: 20,
                      color: AppColors.confirmed,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          AppStrings.profileTotalDaysLabel,
                          style:
                              TextStyle(fontSize: 12, color: AppColors.textSub),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppStrings.homeTotalDays(profile.totalReadingDays),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 3. 받은 뱃지 선반
            Row(
              children: [
                const Text(
                  AppStrings.profileBadges,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  AppStrings.profileBadgeCount(profile.badgeIds.length),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              AppStrings.profileBadgesCaption,
              style: AppText.caption,
            ),
            const SizedBox(height: 16),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: profile.badgeIds.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.85,
              ),
              itemBuilder: (context, index) {
                final badgeId = profile.badgeIds[index];
                return _BadgeItem(
                  badgeId: badgeId,
                  poemTitle: data.badgeTitles[badgeId] ?? '',
                );
              },
            ),

            if (profile.badgeIds.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 40),
                alignment: Alignment.center,
                child: const Text(
                  AppStrings.profileNoBadges,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.textFaint,
                  ),
                ),
              ),

            const SizedBox(height: 32),

            if (isMe) ...[
              const Divider(color: AppColors.border),
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  AppStrings.profileShelfNote,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textFaint,
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
  const _BadgeItem({required this.badgeId, required this.poemTitle});

  final String badgeId; // 뱃지 id = poemId
  final String poemTitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.text.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          BadgeImage(poemId: badgeId, size: 48),
          const SizedBox(height: 10),
          // 어느 시의 뱃지인지 (뱃지 자체에는 문구가 없다)
          Text(
            poemTitle,
            textAlign: TextAlign.center,
            style: AppText.lineNumber,
          ),
        ],
      ),
    );
  }
}
