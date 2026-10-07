// S03 홈 — 주인: B
// B의 part-b `S03HomeScreen`을 이름만 맞춰 옮겼다 (docs/여백-이름대조표.md).
// - 누적일수 문구, 오늘의 시, 내가 읽은 시
// - 상단 프로필 → S12
// - 하단 탭바는 C의 TabShell이 감싸서 붙임
import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../data/fakes/fake_data.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final poem = FakeData.poemById(FakeData.todayPoemId);
    final me = FakeData.profileById(FakeData.myUserId);
    final readPoems = FakeData.poems
        .where((p) => FakeData.readingFor(p.poemId) != null)
        .toList();

    void openReading(String poemId) =>
        Navigator.of(context).pushNamed(AppRoutes.reading(poemId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        backgroundColor: AppColors.background,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: AppStrings.homeProfileTooltip,
            onPressed: () => Navigator.of(context)
                .pushNamed(AppRoutes.profile(FakeData.myUserId)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            AppStrings.homeTotalDays(me.totalReadingDays),
            style: const TextStyle(fontSize: 16, color: AppColors.textSub),
          ),
          const SizedBox(height: 24),
          const Text(
            AppStrings.homeTodayPoem,
            style: TextStyle(color: AppColors.textFaint),
          ),
          const SizedBox(height: 8),
          Card(
            color: AppColors.card,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    poem.title,
                    style: const TextStyle(
                      fontFamily: AppFonts.myeongjo,
                      fontSize: 22,
                    ),
                  ),
                  Text(
                    poem.author,
                    style: const TextStyle(color: AppColors.textSub),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    poem.lines.take(2).join('\n'),
                    style: const TextStyle(
                      fontFamily: AppFonts.myeongjo,
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => openReading(poem.poemId),
                      child: const Text(AppStrings.homeStartReading),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            AppStrings.homeMyPoems,
            style: TextStyle(color: AppColors.textFaint),
          ),
          for (final p in readPoems)
            ListTile(
              title: Text(
                p.title,
                style: const TextStyle(fontFamily: AppFonts.myeongjo),
              ),
              subtitle: Text(p.author),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => openReading(p.poemId),
            ),
        ],
      ),
    );
  }
}
