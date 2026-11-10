// S03 홈 — 주인: B
import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../data/fakes/fake_data.dart';
import '../../data/models/poem.dart';


//AI
// 추가된 순서대로 하루에 한 편씩 돌아감 (기획서 9장 3번)
Poem todayPoem(List<Poem> poems, DateTime now) {
  // 1970년 1월 1일부터 오늘까지 며칠 지났는지
  DateTime today = DateTime.utc(now.year, now.month, now.day);
  int days = today.difference(DateTime.utc(1970, 1, 1)).inDays;

  int index = days % poems.length;
  return poems[index];
}



class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final poem =  todayPoem(FakeData.poems, DateTime.now());
    final me = FakeData.profileById(FakeData.myUserId);

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
            AppStrings.homePoemList,
            style: TextStyle(color: AppColors.textFaint),
          ),


          for (final p in FakeData.poems) //AI
            ListTile(
              title: Text(p.title, style: const TextStyle(fontFamily: AppFonts.myeongjo)),
              subtitle: Text(p.author),
              trailing: FakeData.readingFor(p.poemId)==null
                    ? const Icon(Icons.chevron_right)
                    : const Text(AppStrings.homeReadMark, style: AppText.caption),
                onTap: () => openReading(p.poemId)
            ),
        ],
      ),
    );
  }
}
