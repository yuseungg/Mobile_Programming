// S06 정리 · 저장 — 주인: B
// B의 part-b `S06SaveScreen`을 이름만 맞춰 옮겼다 (docs/여백-이름대조표.md).
// - 대화에서 사용자가 한 말만 모은 초안을 직접 고침 (최대 500자)
// - 근거 구절 모음, 공개 선택 (기본 꺼짐)
// - 저장 → S07. 대조를 연 뒤에는 수정 불가라 되돌아오지 않게 교체 이동
import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../data/fakes/fake_data.dart';
import '../../data/models/chat_message.dart';

class SaveScreen extends StatefulWidget {
  const SaveScreen({super.key, required this.poemId});

  final String poemId;

  @override
  State<SaveScreen> createState() => _SaveScreenState();
}

class _SaveScreenState extends State<SaveScreen> {
  // 초안 = 대화에서 사용자가 한 말만 (AI가 다듬지 않음)
  late final _interpretationController = TextEditingController(
    text: (FakeData.readingFor(widget.poemId)?.conversation ?? const [])
        .where((message) => message.role == ChatRole.user)
        .map((message) => message.text)
        .join('\n'),
  );
  bool _isPublic = false;

  @override
  void dispose() {
    _interpretationController.dispose();
    super.dispose();
  }

  void _save() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.comparison(widget.poemId),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final poem = FakeData.poemById(widget.poemId);
    final evidenceLines =
        FakeData.readingFor(widget.poemId)?.evidenceLines ?? const <int>[];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.saveTitle),
        backgroundColor: AppColors.background,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            AppStrings.saveDraftNotice,
            style: TextStyle(color: AppColors.textSub),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _interpretationController,
            maxLength: 500,
            minLines: 6,
            maxLines: null,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(
              fontFamily: AppFonts.myeongjo,
              fontSize: 18,
              height: 1.7,
              color: AppColors.text,
            ),
            decoration: const InputDecoration(
              filled: true,
              fillColor: AppColors.card,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            AppStrings.saveEvidenceLabel,
            style: TextStyle(color: AppColors.textFaint),
          ),
          for (final lineNo in evidenceLines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(width: 20, height: 2, color: AppColors.confirmed),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      poem.lineAt(lineNo),
                      style: const TextStyle(
                        fontFamily: AppFonts.myeongjo,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text(AppStrings.savePublicLabel),
            subtitle: const Text(AppStrings.savePublicCaption),
            value: _isPublic,
            onChanged: (value) => setState(() => _isPublic = value),
          ),
        ],
      ),
      // 저장 버튼은 화면 아래 고정 (화면설계 PDF)
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton(
              // 잠금을 여는 버튼은 와인색 (화면설계 PDF)
              style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
              onPressed:
                  _interpretationController.text.trim().isEmpty ? null : _save,
              child: const Text(AppStrings.saveButton),
            ),
            const SizedBox(height: 8),
            const Text(
              AppStrings.saveLockNotice,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textFaint),
            ),
          ],
        ),
      ),
    );
  }
}
