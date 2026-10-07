// S12 프로필 — 주인: D
// 닉네임 · 누적일수 · 받은 뱃지. 내 것과 남의 것을 같은 화면으로.
// 프로필에 없는 것: 팔로워 수, 총 공감 수, 순위, 공개한 대화 목록 (기획서 F8)
import 'package:flutter/material.dart';

import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../data/fakes/fake_data.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/badge_image.dart';
import '../../shared/widgets/section_label.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    final profile = FakeData.profileById(userId);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.profileTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            const Center(
              child: Icon(Icons.account_circle,
                  size: 84, color: AppColors.textFaint),
            ),
            const SizedBox(height: 10),
            Center(child: Text(profile.nickname, style: AppText.heading)),
            const SizedBox(height: 24),
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Column(
                children: [
                  Text(
                    AppStrings.profileTotalDays(profile.totalReadingDays),
                    style: AppText.poemTitle.copyWith(color: AppColors.accent),
                  ),
                  const SizedBox(height: 2),
                  const Text(AppStrings.profileTotalDaysLabel,
                      style: AppText.caption),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const SectionLabel(AppStrings.profileBadges),
            if (profile.badgeIds.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(AppStrings.profileNoBadges,
                      style: AppText.bodySub),
                ),
              )
            else
              // 선반 — 뱃지는 문구 없이 이미지만
              AppCard(
                child: Wrap(
                  spacing: 18,
                  runSpacing: 18,
                  children: [
                    for (final badgeId in profile.badgeIds)
                      BadgeImage(poemId: badgeId),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
