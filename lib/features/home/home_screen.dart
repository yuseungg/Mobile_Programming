// S03 홈 — 주인: B
// 누적일수 문구, 오늘의 시, 내가 읽은 시, 상단 프로필 진입. 탭바는 TabShell이 붙인다.
import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../data/fakes/fake_data.dart';
import '../../data/models/poem.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/section_label.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final me = FakeData.profileById(FakeData.myUserId);
    final todayPoem = FakeData.poemById(FakeData.todayPoemId);
    final myPoems = FakeData.poems
        .where((poem) => FakeData.readingFor(poem.poemId) != null)
        .toList();
    final otherPoems = FakeData.poems
        .where((poem) => FakeData.readingFor(poem.poemId) == null)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName, style: AppText.appNameSmall),
        actions: [
          IconButton(
            tooltip: AppStrings.homeProfileTooltip,
            onPressed: () => Navigator.of(context)
                .pushNamed(AppRoutes.profile(FakeData.myUserId)),
            icon: const Icon(Icons.account_circle_outlined, size: 28),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            AppStrings.homeTotalDays(me.totalReadingDays),
            style: AppText.heading,
          ),
          const SizedBox(height: 24),
          _TodayPoemCard(poem: todayPoem),
          const SizedBox(height: 32),
          if (myPoems.isNotEmpty) ...[
            const SectionLabel(AppStrings.homeMyPoems),
            for (final poem in myPoems) ...[
              _PoemTile(poem: poem),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 22),
          ],
          if (otherPoems.isNotEmpty) ...[
            const SectionLabel(AppStrings.homeOtherPoems),
            for (final poem in otherPoems) ...[
              _PoemTile(poem: poem),
              const SizedBox(height: 10),
            ],
          ],
        ],
      ),
    );
  }
}

class _TodayPoemCard extends StatelessWidget {
  const _TodayPoemCard({required this.poem});

  final Poem poem;

  @override
  Widget build(BuildContext context) {
    final preview = poem.lines.where((line) => line.isNotEmpty).take(2);

    return AppCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(AppStrings.homeTodayPoem, style: AppText.label),
          const SizedBox(height: 12),
          Text(poem.title, style: AppText.poemTitle),
          const SizedBox(height: 2),
          Text(poem.author, style: AppText.caption),
          const SizedBox(height: 14),
          for (final line in preview) Text(line, style: AppText.poemQuote),
          const SizedBox(height: 20),
          AppPrimaryButton(
            label: AppStrings.homeStartReading,
            onPressed: () => Navigator.of(context)
                .pushNamed(AppRoutes.reading(poem.poemId)),
          ),
        ],
      ),
    );
  }
}

class _PoemTile extends StatelessWidget {
  const _PoemTile({required this.poem});

  final Poem poem;

  @override
  Widget build(BuildContext context) {
    final reading = FakeData.readingFor(poem.poemId);
    final String? status = reading == null
        ? null
        : reading.isSaved
            ? AppStrings.homeStatusSaved
            : AppStrings.homeStatusInProgress;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      onTap: () =>
          Navigator.of(context).pushNamed(AppRoutes.reading(poem.poemId)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(poem.title, style: AppText.poemTitleSmall),
                const SizedBox(height: 2),
                Text(poem.author, style: AppText.caption),
              ],
            ),
          ),
          if (status != null)
            _StatusChip(label: status, isSaved: reading?.isSaved ?? false),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right, color: AppColors.textFaint),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.isSaved});

  final String label;
  final bool isSaved;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isSaved ? AppColors.background : AppColors.accentBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: AppText.caption.copyWith(
          color: isSaved ? AppColors.confirmed : AppColors.accent,
        ),
      ),
    );
  }
}
