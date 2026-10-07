// S06 정리 · 저장 — 주인: B
// 초안 편집(사용자가 한 말만 모은 것), 근거 구절, 공개 토글, 저장.
// 1단계: 저장은 S07로 넘어가기만. 실제 저장 · 잠금 해제 · 뱃지는 2단계.
import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../data/fakes/fake_data.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/section_label.dart';

class SaveScreen extends StatefulWidget {
  const SaveScreen({super.key, required this.poemId});

  final String poemId;

  @override
  State<SaveScreen> createState() => _SaveScreenState();
}

class _SaveScreenState extends State<SaveScreen> {
  late final _interpretationController = TextEditingController(
    text: FakeData.readingFor(widget.poemId)?.interpretation ?? '',
  );
  late bool _isPublic = FakeData.readingFor(widget.poemId)?.isPublic ?? false;

  @override
  void dispose() {
    _interpretationController.dispose();
    super.dispose();
  }

  void _save() {
    // 저장 뒤 뒤로 가기는 홈으로 — 대화 · 정리 화면으로 돌아가지 않는다.
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.comparison(widget.poemId),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final poem = FakeData.poemById(widget.poemId);
    final evidenceLines = FakeData.readingFor(widget.poemId)?.evidenceLines ??
        const <int>[];

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.saveTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            const Text(AppStrings.saveDraftNotice, style: AppText.bodySub),
            const SizedBox(height: 14),
            AppTextField(
              controller: _interpretationController,
              maxLines: 9,
              minLines: 6,
              counterMax: 500,
              style: AppText.interpretation,
            ),
            if (evidenceLines.isNotEmpty) ...[
              const SizedBox(height: 22),
              const SectionLabel(AppStrings.saveEvidenceLabel),
              for (final lineNo in evidenceLines)
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.only(left: 12),
                  decoration: const BoxDecoration(
                    border: Border(
                      left: BorderSide(color: AppColors.confirmed, width: 2),
                    ),
                  ),
                  child: Text(poem.lineAt(lineNo), style: AppText.poemQuote),
                ),
            ],
            const SizedBox(height: 22),
            AppCard(
              padding: const EdgeInsets.fromLTRB(18, 10, 10, 12),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppStrings.savePublicLabel,
                            style: AppText.bodyStrong),
                        SizedBox(height: 2),
                        Text(AppStrings.savePublicCaption,
                            style: AppText.caption),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isPublic,
                    onChanged: (value) => setState(() => _isPublic = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            AppPrimaryButton(
              label: AppStrings.saveButton,
              isUnlock: true,
              onPressed: _save,
            ),
            const SizedBox(height: 10),
            const Text(
              AppStrings.saveLockNotice,
              style: AppText.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
