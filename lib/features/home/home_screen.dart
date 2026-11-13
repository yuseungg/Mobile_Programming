// S03 홈 — 주인: B
import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../data/fakes/fake_data.dart';
import '../../data/models/poem.dart';
import '../../data/models/reading.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories.dart';


//AI
// 추가된 순서대로 하루에 한 편씩 돌아감 (기획서 9장 3번)
Poem todayPoem(List<Poem> poems, DateTime now) {
  // 1970년 1월 1일부터 오늘까지 며칠 지났는지
  DateTime today = DateTime.utc(now.year, now.month, now.day);
  int days = today.difference(DateTime.utc(1970, 1, 1)).inDays;

  int index = days % poems.length;
  return poems[index];
}



class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // S01이 아직 진짜 로그인을 안 시켜서 없으면 가짜 계정으로
  final String _userId = Repositories.auth.currentUserId ?? FakeData.myUserId;

  UserProfile? _me;
  Set<String> _readPoemIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    UserProfile me = await Repositories.user.fetchProfile(_userId);
    List<Reading> readings = await Repositories.reading.fetchMyReadings(_userId);

    Set<String> ids = {};
    for (Reading reading in readings) {
      ids.add(reading.poemId);
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _me = me;
      _readPoemIds = ids;
    });
  }

  // 읽기 화면에서 돌아오면 누적일수랑 읽음 표시 다시 불러옴
  void openReading(String poemId) {
    Navigator.of(context).pushNamed(AppRoutes.reading(poemId)).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final poem =  todayPoem(FakeData.poems, DateTime.now());

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
                .pushNamed(AppRoutes.profile(_userId)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            _me == null ? '' : AppStrings.homeTotalDays(_me!.totalReadingDays),
            style: AppText.bodySub,
          ),
          const SizedBox(height: 24),
          const Text(
            AppStrings.homeTodayPoem,
            style: AppText.label,
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
                    style: AppText.poemTitle,
                  ),
                  Text(
                    poem.author,
                    style:  AppText.bodySub,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    poem.lines.take(2).join('\n'),
                    style: AppText.poemQuote,
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
            style: AppText.label,
          ),


          for (final p in FakeData.poems) //AI
            ListTile(
              title: Text(p.title, style: AppText.poemTitleSmall),
              subtitle: Text(p.author),
              trailing: _readPoemIds.contains(p.poemId)
                    ? const Text(AppStrings.homeReadMark, style: AppText.caption)
                    : const Icon(Icons.chevron_right),
                onTap: () => openReading(p.poemId)
            ),
        ],
      ),
    );
  }
}
