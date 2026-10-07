// S04 읽기 — 주인: B
// AI 없이 혼자 읽기. 멈춘 행 표시, 첫 낱말 입력.
// 1단계: 행 탭은 화면 안에서만 표시된다. 저장 · 멈춤 집계 · 누적일수는 2단계.
import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../data/fakes/fake_data.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/poem_view.dart';

class ReadingScreen extends StatefulWidget {
  const ReadingScreen({super.key, required this.poemId});

  final String poemId;

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  late final _poem = FakeData.poemById(widget.poemId);
  late final Set<int> _markedLines = {
    ...?FakeData.readingFor(widget.poemId)?.markedLines,
  };
  late final _firstWordController = TextEditingController(
    text: FakeData.readingFor(widget.poemId)?.firstWord ?? '',
  );

  @override
  void dispose() {
    _firstWordController.dispose();
    super.dispose();
  }

  void _toggleLine(int lineNo) {
    setState(() {
      if (!_markedLines.remove(lineNo)) _markedLines.add(lineNo);
    });
  }

  @override
  Widget build(BuildContext context) {
    final poem = _poem;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.readingAppBarTitle(poem.author, poem.title),
          style: AppText.bodySub,
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
          children: [
            Text(poem.title, style: AppText.poemTitle.copyWith(fontSize: 30)),
            const SizedBox(height: 4),
            Text(
              AppStrings.readingAuthorYear(poem.author, poem.year),
              style: AppText.caption,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.only(left: 4),
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: AppColors.border, width: 2),
                ),
              ),
              child: PoemView(
                poem: poem,
                markedLines: _markedLines,
                stopCounts: FakeData.stopCounts[poem.poemId] ?? const {},
                onLineTap: _toggleLine,
              ),
            ),
            const SizedBox(height: 14),
            const Text(AppStrings.readingStopGuide, style: AppText.caption),
            const SizedBox(height: 28),
            AppTextField(
              controller: _firstWordController,
              label: AppStrings.readingFirstWordLabel,
              hintText: AppStrings.readingFirstWordHint,
              counterMax: 20,
            ),
            const SizedBox(height: 24),
            AppPrimaryButton(
              label: AppStrings.readingStartChat,
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoutes.chat(poem.poemId)),
            ),
            const SizedBox(height: 10),
            AppSecondaryButton(
              label: AppStrings.readingEndWithWord,
              onPressed: () => AppRouter.goToTab(context, AppRoutes.home),
            ),
          ],
        ),
      ),
    );
  }
}
