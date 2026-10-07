// S04 읽기 — 주인: B
// B의 part-b `S04ReadingScreen`을 이름만 맞춰 옮겼다 (docs/여백-이름대조표.md).
// - AI 없이 혼자 읽기. 마음이 멈춘 행을 눌러 표시
// - 떠오른 낱말 하나 (최대 20자) → 대화의 출발점
import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../data/fakes/fake_data.dart';
import '../../shared/widgets/poem_view.dart';

class ReadingScreen extends StatefulWidget {
  const ReadingScreen({super.key, required this.poemId});

  final String poemId;

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  final _markedLines = <int>{};
  final _firstWordController = TextEditingController();

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
            stopCounts: FakeData.stopCounts[poem.poemId] ?? const {},
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
