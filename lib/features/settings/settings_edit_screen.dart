// S11 설정 바꾸기 — 주인: C · 요건 (d) 설정을 변경하는 화면
// 질문 모델 · 비교 모델(각각 하나 선택), 말투(둘 중 하나), 대화 기록 지우기, 저장.
// 1단계: 선택은 화면 안에서만 바뀐다. 저장하면 S10으로 돌아가기만 한다.
import 'package:flutter/material.dart';

import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../data/fakes/fake_data.dart';
import '../../data/models/settings.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/section_label.dart';

class SettingsEditScreen extends StatefulWidget {
  const SettingsEditScreen({super.key});

  @override
  State<SettingsEditScreen> createState() => _SettingsEditScreenState();
}

class _SettingsEditScreenState extends State<SettingsEditScreen> {
  String _questionModel = FakeData.settings.questionModel;
  String _comparisonModel = FakeData.settings.comparisonModel;
  Tone _tone = FakeData.settings.tone;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.settingsEditTitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.settingsEditSave),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            const SectionLabel(AppStrings.settingsEditQuestionModel),
            _ModelPicker(
              selected: _questionModel,
              onSelected: (model) => setState(() => _questionModel = model),
            ),
            const SizedBox(height: 24),
            const SectionLabel(AppStrings.settingsEditComparisonModel),
            _ModelPicker(
              selected: _comparisonModel,
              onSelected: (model) => setState(() => _comparisonModel = model),
            ),
            const SizedBox(height: 24),
            const SectionLabel(AppStrings.settingsEditTone),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<Tone>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: Tone.plain,
                    label: Text(AppStrings.tonePlain),
                  ),
                  ButtonSegment(
                    value: Tone.gentle,
                    label: Text(AppStrings.toneGentle),
                  ),
                ],
                selected: {_tone},
                onSelectionChanged: (selection) =>
                    setState(() => _tone = selection.first),
              ),
            ),
            const SizedBox(height: 24),
            AppCard(
              padding: const EdgeInsets.fromLTRB(18, 4, 8, 4),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      AppStrings.settingsEditDeleteHistory,
                      style: AppText.bodyStrong,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(AppStrings.settingsEditDeleteAction),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 모델 하나 고르기 — 반드시 하나는 선택된 상태
class _ModelPicker extends StatelessWidget {
  const _ModelPicker({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    const options = FakeData.modelOptions;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) const Divider(),
            ListTile(
              onTap: () => onSelected(options[i].model),
              title: Text(options[i].model, style: AppText.bodyStrong),
              subtitle: Text(options[i].description, style: AppText.caption),
              trailing: options[i].model == selected
                  ? const Icon(Icons.check_rounded, color: AppColors.confirmed)
                  : null,
            ),
          ],
        ],
      ),
    );
  }
}
