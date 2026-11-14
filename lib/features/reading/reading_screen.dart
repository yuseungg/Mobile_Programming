// S04 읽기 — 주인: B
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/router.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../data/fakes/fake_data.dart';
import '../../data/models/reading.dart';
import '../../data/repositories.dart';
import '../../shared/widgets/poem_view.dart';

class ReadingScreen extends StatefulWidget {
  const ReadingScreen({super.key, required this.poemId});

  final String poemId;

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  // S01이 아직 진짜 로그인을 안 시켜서 없으면 가짜 계정으로
  final String _userId = Repositories.auth.currentUserId ?? FakeData.myUserId;

  final Set<int> _markedLines = {};
  Map<int, int> _stopCounts = {};
  final TextEditingController _firstWordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _countReadingDay();
    _load();
  }

  // 들어올 때 누적일수 셈 (한국 시간 기준 하루 한 번, 저장소에서 처리)
  // 네트워크 문제로 못 세도 읽기는 그냥 되게 함
  Future<void> _countReadingDay() async {
    try {
      await Repositories.user.countReadingDay(_userId);
    } catch (e) {
      // print(e);
    }
  }

  Future<void> _load() async {
    // 전에 읽던 시면 멈춘 행이랑 첫 낱말 그대로 불러옴
    Reading? saved = await Repositories.reading.fetchReading(_userId, widget.poemId);
    Map<int, int> counts = await Repositories.reading.fetchStopCounts(widget.poemId);
    // print(counts);

    if (!mounted) {
      return;
    }
    setState(() {
      if (saved != null) {
        _markedLines.addAll(saved.markedLines);
        _firstWordController.text = saved.firstWord;
      }
      _stopCounts = counts;
    });
  }



  //AI
  // 누르면 내 멈춘 행이랑 집계가 같이 바뀜. 집계엔 나도 들어가 있어서 다시 받아옴
  Future<void> _toggleLine(int lineNo) async {
    bool isMarked = !_markedLines.contains(lineNo);
    setState(() {
      if (isMarked) {
        _markedLines.add(lineNo);
      } else {
        _markedLines.remove(lineNo);
      }
    });

    await Repositories.reading.setMarkedLine(_userId, widget.poemId, lineNo, isMarked: isMarked);
    Map<int, int> counts = await Repositories.reading.fetchStopCounts(widget.poemId);
    if (!mounted) {
      return;
    }
    setState(() {
      _stopCounts = counts;
    });
  }

  // 첫 낱말 저장. S05가 저장소에서 이걸 꺼내 씀
  Future<void> _saveFirstWord() async {
    Reading? latest = await Repositories.reading.fetchReading(_userId, widget.poemId);
    latest ??= Reading(poemId: widget.poemId);
    await Repositories.reading.saveProgress(_userId, latest.copyWith(firstWord: _firstWordController.text.trim()));
  }

  Future<void> _startChat() async {
    await _saveFirstWord();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushNamed(AppRoutes.chat(widget.poemId));
  }

  Future<void> _endWithWord() async {
    await _saveFirstWord();
    if (!mounted) {
      return;
    }
    AppRouter.goToTab(context, AppRoutes.home);
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
          style: AppText.bodySub,
        ),
        backgroundColor: AppColors.background,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            poem.title,
            style: AppText.poemTitle,
          ),
          Text(
            AppStrings.readingAuthorYear(poem.author, poem.year),
            style:AppText.bodySub,
          ),
          const SizedBox(height: 24),
          PoemView(
            poem: poem,
            markedLines: _markedLines,
            stopCounts: _stopCounts,
            onLineTap: _toggleLine,
          ),
          const SizedBox(height: 8),
          const Text(
            AppStrings.readingStopGuide,
            style: AppText.caption,
          ),
          const SizedBox(height: 32),
          const Text(
            AppStrings.readingFirstWordLabel,
            style: AppText.label,
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
            onPressed: !hasFirstWord ? null : _startChat,
            child: const Text(AppStrings.readingStartChat),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: !hasFirstWord ? null : _endWithWord,
            child: const Text(AppStrings.readingEndWithWord),
          ),
        ],
      ),
    );
  }
}
