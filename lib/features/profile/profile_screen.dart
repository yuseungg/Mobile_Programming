// S12 프로필 — 주인: D
// D의 part-d `S12ProfileScreen`을 이름만 맞춰 옮겼다 (docs/여백-이름대조표.md).
// - '보여주는 선반': 닉네임, 누적일수, 받은 뱃지
// - 팔로워 수, 총 공감 수, 순위, 공개한 대화 목록은 없다 (기획서 F8)
// - 내 것 · 남의 것 겸용. 내 것인지는 userId로 판단
// - 뱃지는 문구 없이 이미지만 (기획서 F8) — part-d의 뱃지 이름(별 · 꽃 · 고양이) 글자는 뺐다
// - 프로필을 구독한다 (C의 watchProfile) — 뱃지·누적일수가 바로 반영된다
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
  late final Stream<_ProfileData> _data = _watch();

  /// 프로필을 구독한다 — 뱃지를 받거나 누적일수가 오르면 화면을 다시 열지
  /// 않아도 바뀐다. 전에는 한 번만 읽어서, S06에서 저장해 뱃지를 받아도
  /// 이 화면을 닫고 다시 열어야 보였다.
  Stream<_ProfileData> _watch() async* {
    final source = widget.source;

    // 뱃지 id는 시 id다. 시 목록은 바뀌지 않으므로 제목을 한 번만 모아 두고
    // 갱신마다 다시 읽지 않는다 (전에는 뱃지 하나마다 poemById를 불렀다).
    final titles = {
      for (final poem in await source.poems()) poem.poemId: poem.title,
    };
    final myUserId = source.myUserId;

    _ProfileData wrap(UserProfile profile) => _ProfileData(
          profile: profile,
          isMe: profile.userId == myUserId,
          badgeTitles: {
            for (final badgeId in profile.badgeIds)
              badgeId: titles[badgeId] ?? badgeId,
          },
        );

    // 먼저 한 번 읽는다. watchProfile은 프로필이 없으면 아무것도 내보내지
    // 않아서, 이것 없이는 없는 사람의 화면이 영원히 로딩에 머문다.
    yield wrap(await source.profileById(widget.userId));

    await for (final profile in source.watchProfile(widget.userId)) {
      yield wrap(profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<_ProfileData>(
      stream: _data,
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
                      style: AppText.avatarInitial,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    profile.nickname,
                    style: AppText.profileName,
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
                        Text(
                          AppStrings.profileTotalDaysLabel,
                          style:
                              AppText.caption.copyWith(color: AppColors.textSub),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppStrings.homeTotalDays(profile.totalReadingDays),
                          style: AppText.sectionTitle,
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
                Text(
                  AppStrings.profileBadges,
                  style: AppText.sectionTitle.copyWith(fontSize: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  AppStrings.profileBadgeCount(profile.badgeIds.length),
                  style: AppText.badgeCount,
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
                child: Text(
                  AppStrings.profileNoBadges,
                  textAlign: TextAlign.center,
                  style: AppText.caption.copyWith(fontSize: 13),
                ),
              ),

            const SizedBox(height: 32),

            if (isMe) ...[
              const Divider(color: AppColors.border),
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  AppStrings.profileShelfNote,
                  style: AppText.captionItalic,
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
