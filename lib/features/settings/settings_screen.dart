// S10 설정 보기 — 주인: C · 요건 (c) 설정을 기억하는 화면
// 용도별 모델 배정, 말투, 이번 달 사용량. 읽기 전용.
// 1단계: 가짜 설정을 보여준다. SharedPreferences는 2단계.
import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../data/fakes/fake_data.dart';
import '../../data/models/settings.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/section_label.dart';

String toneLabel(Tone tone) => switch (tone) {
      Tone.plain => AppStrings.tonePlain,
      Tone.gentle => AppStrings.toneGentle,
    };

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const settings = FakeData.settings;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          const SectionLabel(AppStrings.settingsModelSection),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(
                  label: AppStrings.settingsQuestionModel,
                  value: settings.questionModel,
                ),
                const Divider(),
                _InfoRow(
                  label: AppStrings.settingsComparisonModel,
                  value: settings.comparisonModel,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(AppStrings.settingsModelCaption, style: AppText.caption),
          const SizedBox(height: 28),
          const SectionLabel(AppStrings.settingsToneSection),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Text(toneLabel(settings.tone), style: AppText.bodyStrong),
          ),
          const SizedBox(height: 28),
          const SectionLabel(AppStrings.settingsUsageSection),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Text(
              AppStrings.settingsUsage(
                FakeData.usageQuestionCount,
                FakeData.usageComparisonCount,
              ),
              style: AppText.bodyStrong,
            ),
          ),
          const SizedBox(height: 36),
          AppPrimaryButton(
            label: AppStrings.settingsEditButton,
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.settingsEdit),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.label),
          const SizedBox(height: 4),
          Text(value, style: AppText.bodyStrong),
        ],
      ),
    );
  }
}
