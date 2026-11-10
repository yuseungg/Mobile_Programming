// S04 읽기 — 주인: B
// B의 part-b `S04ReadingScreen`을 이름만 맞춰 옮겼다 (docs/여백-이름대조표.md).
// - AI 없이 혼자 읽기. 마음이 멈춘 행을 눌러 표시
// - 떠오른 낱말 하나 (최대 20자) → 대화의 출발점
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/router.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../data/fakes/fake_data.dart';
import '../../data/models/reading.dart';
import '../../data/models/user_profile.dart';
import '../../shared/widgets/poem_view.dart';


//AI
// S04 들어올 때 누적일수 셈. 같은 날이면 그대로, 날짜 바뀌면 +1 (연속 아님)
UserProfile countReadingDay(UserProfile me, DateTime today) {
  DateTime last = me.lastCountedDate;
  bool isSameDay = last.year==today.year && last.month == today.month && last.day==today.day;
  if (isSameDay) {
    return me;
  }

  int newDays = me.totalReadingDays + 1;
  DateTime newDate = DateTime(today.year, today.month, today.day);
  return UserProfile(userId: me.userId, nickname: me.nickname,
      totalReadingDays: newDays,
      lastCountedDate: newDate,
      badgeIds: me.badgeIds);
}

class ReadingScreen extends StatefulWidget {
  const ReadingScreen({super.key, required this.poemId});

  final String poemId;

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  Reading? _saved;
  final Set<int> _markedLines = {};
  final TextEditingController _firstWordController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // 전에 읽던 시면 멈춘 행이랑 첫 낱말 그대로 불러옴
    _saved = FakeData.readingFor(widget.poemId);
    if (_saved != null) {
      _markedLines.addAll(_saved!.markedLines);
      _firstWordController.text = _saved!.firstWord;
    }

    // 지금은 기기 날짜로 가짜 프로필에 반영. 저장소 붙이면 서버 시간으로 바꿔야 함
    UserProfile me = FakeData.profileById(FakeData.myUserId);
    FakeData.profiles[FakeData.myUserId] = countReadingDay(me, DateTime.now());
  }



  //AI
  // 집계엔 저장돼 있던 내 멈춤이 이미 들어 있어서 그건 빼고 지금 누른 걸 더함
  Map<int, int> _stopCountsWithMe(String poemId) {
    Map<int, int> counts = {};
    Map<int, int>? others = FakeData.stopCounts[poemId];
    if (others != null) {
      counts.addAll(others);
    }

    if (_saved != null) {
      for (int lineNo in _saved!.markedLines) {
        counts[lineNo] = (counts[lineNo] ?? 0) - 1;
      }
    }
    for (int lineNo in _markedLines) {
      counts[lineNo] = (counts[lineNo] ?? 0) + 1;
    }
    // print(counts);
    return counts;
  }

  @override
  void dispose() {
    _firstWordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final poem = FakeData.poemById(widget.poemId);
    // 낱말은 필수. 입력해야 두 버튼이 켜짐
    final hasFirstWord = _firstWordController.text.trim().isNotEmpty;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppStrings.readingAppBarTitle(poem.author, poem.title),
          style: const TextStyle(fontSize: 15, color: AppColors.textSub),
        ),
        backgroundColor: AppColors.background,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            poem.title,
            style: const TextStyle(
              fontFamily: AppFonts.myeongjo,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          Text(
            AppStrings.readingAuthorYear(poem.author, poem.year),
            style: const TextStyle(color: AppColors.textSub),
          ),
          const SizedBox(height: 24),
          PoemView(
            poem: poem,
            markedLines: _markedLines,
            stopCounts: _stopCountsWithMe(poem.poemId),
            onLineTap: (lineNo) => setState(
              () => _markedLines.contains(lineNo)
                  ? _markedLines.remove(lineNo)
                  : _markedLines.add(lineNo),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            AppStrings.readingStopGuide,
            style: TextStyle(fontSize: 12, color: AppColors.textFaint),
          ),
          const SizedBox(height: 32),
          const Text(
            AppStrings.readingFirstWordLabel,
            style: TextStyle(fontSize: 13, color: AppColors.textSub),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _firstWordController,
            maxLength: 20,
            //웹 기본값은 한글 조합 중엔 제한을 풀어서 20자 넘어감
              maxLengthEnforcement:  MaxLengthEnforcement.enforced,//AI
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              filled: true,
              fillColor: AppColors.input,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: !hasFirstWord
                ? null
                : () => Navigator.of(context)
                    .pushNamed(AppRoutes.chat(poem.poemId)),
            child: const Text(AppStrings.readingStartChat),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: !hasFirstWord
                ? null
                : () => AppRouter.goToTab(context, AppRoutes.home),
            child: const Text(AppStrings.readingEndWithWord),
          ),
        ],
      ),
    );
  }
}
