// S11 설정 바꾸기 — 주인: C · 요건 (d) 설정을 변경하는 화면
// 질문 모델 · 비교 모델(각각 하나 선택), 말투(둘 중 하나), 대화 기록 지우기, 저장.
// - 저장하면 Repositories.settings에 쓰고 S10으로 돌아간다. 바뀐 게 없으면 저장 버튼은 꺼져 있다.
// - 대화 기록 지우기는 확인 창을 거친다. 모든 읽기의 대화만 비우고,
//   저장한 해석 · 뱃지 · 누적일수 · 공개한 대화는 남긴다 (ReadingRepository.clearConversations).
import 'package:flutter/material.dart';

import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../data/fakes/fake_data.dart';
import '../../data/models/settings.dart';
import '../../data/repositories.dart';
import '../../data/settings_options.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/section_label.dart';

class SettingsEditScreen extends StatefulWidget {
  const SettingsEditScreen({super.key});

  @override
  State<SettingsEditScreen> createState() => _SettingsEditScreenState();
}

class _SettingsEditScreenState extends State<SettingsEditScreen> {
  Settings? _saved; // 저장소에 있는 값 — 다 읽기 전에는 null
  Settings? _draft; // 화면에서 고르는 중인 값
  bool _hasLoadFailed = false;
  bool _isSaving = false;
  bool _isDeleting = false;

  bool get _isChanged {
    final saved = _saved;
    final draft = _draft;
    if (saved == null || draft == null) return false;
    return saved.questionModel != draft.questionModel ||
        saved.comparisonModel != draft.comparisonModel ||
        saved.tone != draft.tone;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final settings = await Repositories.settings.load();
      if (!mounted) return;
      setState(() {
        _saved = settings;
        _draft = settings;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _hasLoadFailed = true);
    }
  }

  void _update(Settings Function(Settings draft) change) {
    final draft = _draft;
    if (draft == null) return;
    setState(() => _draft = change(draft));
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save() async {
    final draft = _draft;
    if (draft == null || !_isChanged || _isSaving) return;
    setState(() => _isSaving = true);
    try {
      await Repositories.settings.save(draft);
      if (!mounted) return;
      _showMessage(AppStrings.settingsEditSaved);
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showMessage(AppStrings.settingsEditSaveFailed);
    }
  }

  Future<void> _deleteHistory() async {
    final isConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.settingsDeleteDialogTitle),
        content: const Text(
          AppStrings.settingsDeleteDialogBody,
          style: AppText.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.settingsDeleteCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(AppStrings.settingsEditDeleteAction),
          ),
        ],
      ),
    );
    if (isConfirmed != true || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      // ⚠ 로그인 분기(④)가 들어오면 '?? FakeData.myUserId'를 뺀다
      final userId = Repositories.auth.currentUserId ?? FakeData.myUserId;
      await Repositories.reading.clearConversations(userId);
      if (!mounted) return;
      _showMessage(AppStrings.settingsDeleteDone);
    } catch (_) {
      if (!mounted) return;
      _showMessage(AppStrings.settingsDeleteFailed);
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = _draft;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.settingsEditTitle),
        actions: [
          TextButton(
            onPressed: _isChanged && !_isSaving ? _save : null,
            child: const Text(AppStrings.settingsEditSave),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: _hasLoadFailed
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    AppStrings.settingsLoadFailed,
                    style: AppText.bodySub,
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : draft == null
                ? const Center(child: CircularProgressIndicator())
                : _content(draft),
      ),
    );
  }

  Widget _content(Settings draft) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        const SectionLabel(AppStrings.settingsEditQuestionModel),
        _ModelPicker(
          selected: draft.questionModel,
          onSelected: (model) =>
              _update((d) => d.copyWith(questionModel: model)),
        ),
        const SizedBox(height: 24),
        const SectionLabel(AppStrings.settingsEditComparisonModel),
        _ModelPicker(
          selected: draft.comparisonModel,
          onSelected: (model) =>
              _update((d) => d.copyWith(comparisonModel: model)),
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
            selected: {draft.tone},
            onSelectionChanged: (selection) =>
                _update((d) => d.copyWith(tone: selection.first)),
          ),
        ),
        const SizedBox(height: 24),
        AppCard(
          padding: const EdgeInsets.fromLTRB(18, 8, 8, 8),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.settingsEditDeleteHistory,
                      style: AppText.bodyStrong,
                    ),
                    SizedBox(height: 2),
                    Text(
                      AppStrings.settingsEditDeleteHistoryCaption,
                      style: AppText.caption,
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _isDeleting ? null : _deleteHistory,
                child: const Text(AppStrings.settingsEditDeleteAction),
              ),
            ],
          ),
        ),
      ],
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
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < modelOptions.length; i++) ...[
            if (i > 0) const Divider(),
            ListTile(
              onTap: () => onSelected(modelOptions[i].model),
              title: Text(modelOptions[i].model, style: AppText.bodyStrong),
              subtitle:
                  Text(modelOptions[i].description, style: AppText.caption),
              trailing: modelOptions[i].model == selected
                  ? const Icon(Icons.check_rounded, color: AppColors.confirmed)
                  : null,
            ),
          ],
        ],
      ),
    );
  }
}
