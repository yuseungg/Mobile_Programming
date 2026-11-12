// S10 설정 보기 — 주인: C · 요건 (c) 설정을 기억하는 화면
// 용도별 모델 배정, 말투, 이번 달 사용량. 읽기 전용.
// 값은 Repositories.settings에서 읽는다 (Firebase 모드는 기기의 SharedPreferences).
// 탭을 다시 누르거나 S11에서 돌아오면 새로 읽는다 (사용량이 그사이 늘었을 수 있다).
import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../data/models/settings.dart';
import '../../data/repositories.dart';
import '../../data/settings_options.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/section_label.dart';

String toneLabel(Tone tone) => switch (tone) {
      Tone.plain => AppStrings.tonePlain,
      Tone.gentle => AppStrings.toneGentle,
    };

/// 화면 한 번에 필요한 것
typedef _SettingsData = ({
  Settings settings,
  ({int questionCount, int comparisonCount}) usage,
});

Future<_SettingsData> _loadSettingsData() async {
  final repository = Repositories.settings;
  return (
    settings: await repository.load(),
    usage: await repository.usageThisMonth(),
  );
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Future<_SettingsData> _data = _loadSettingsData();

  Future<void> _openEdit() async {
    await Navigator.of(context).pushNamed(AppRoutes.settingsEdit);
    if (!mounted) return;
    // 화살표 함수로 쓰면 대입한 Future가 setState에 돌아가 오류가 난다
    setState(() {
      _data = _loadSettingsData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.settingsTitle)),
      body: FutureBuilder<_SettingsData>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  AppStrings.settingsLoadFailed,
                  style: AppText.bodySub,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final data = snapshot.data;
          if (data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return _content(data);
        },
      ),
    );
  }

  Widget _content(_SettingsData data) {
    final settings = data.settings;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        const SectionLabel(AppStrings.settingsModelSection),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ModelRow(
                label: AppStrings.settingsQuestionModel,
                model: settings.questionModel,
              ),
              const Divider(),
              _ModelRow(
                label: AppStrings.settingsComparisonModel,
                model: settings.comparisonModel,
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
              data.usage.questionCount,
              data.usage.comparisonCount,
            ),
            style: AppText.bodyStrong,
          ),
        ),
        const SizedBox(height: 36),
        AppPrimaryButton(
          label: AppStrings.settingsEditButton,
          onPressed: _openEdit,
        ),
      ],
    );
  }
}

/// 용도 · 모델 이름 · 짧은 설명
class _ModelRow extends StatelessWidget {
  const _ModelRow({required this.label, required this.model});

  final String label;
  final String model;

  @override
  Widget build(BuildContext context) {
    final description = modelDescriptionOf(model);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.label),
          const SizedBox(height: 4),
          Text(model, style: AppText.bodyStrong),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(description, style: AppText.caption),
          ],
        ],
      ),
    );
  }
}
