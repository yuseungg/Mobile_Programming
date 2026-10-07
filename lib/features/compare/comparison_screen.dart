// S07 대조 — 주인: D
// 순서 (기획서 4장): 내 해석(가장 위, 가장 무겁게) → 전문가 해석 A → B → 창작 배경 · 다른 사람의 대화
// 각 전문가 해석 = 관계 한 줄 + 비교 문장 + 해석 본문
// 1단계: 관계 · 비교 문장은 가짜 값. compare_with_experts · get_poem_context는 2단계.
import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../data/fakes/fake_data.dart';
import '../../data/models/expert_interpretation.dart';
import '../../data/models/poem.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/poem_view.dart';
import '../../shared/widgets/section_label.dart';

class ComparisonScreen extends StatelessWidget {
  const ComparisonScreen({super.key, required this.poemId});

  final String poemId;

  void _showCreationBackground(BuildContext context, Poem poem) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                AppStrings.comparisonCreationBackgroundTitle,
                style: AppText.label,
              ),
              const SizedBox(height: 12),
              Text(poem.creationBackground, style: AppText.body),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final poem = FakeData.poemById(poemId);
    final reading = FakeData.readingFor(poemId);
    final experts = FakeData.expertInterpretations[poemId] ?? const [];
    final comparisons = FakeData.comparisons[poemId] ?? const [];
    final evidenceLines = reading?.evidenceLines ?? const <int>[];

    return Scaffold(
      appBar: AppBar(title: Text(poem.title, style: AppText.screenTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            // 1. 내 해석 — 가장 위, 가장 무겁게
            AppCard(
              color: AppColors.accentBg,
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(AppStrings.comparisonMine, style: AppText.label),
                  const SizedBox(height: 12),
                  Text(
                    reading?.interpretation ?? '',
                    style: AppText.interpretationLarge,
                  ),
                  if (evidenceLines.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final lineNo in evidenceLines)
                          _LineChip(lineNo: lineNo),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            ExpansionTile(
              shape: const Border(),
              collapsedShape: const Border(),
              tilePadding: const EdgeInsets.symmetric(horizontal: 4),
              title: const Text(
                AppStrings.comparisonPoemToggle,
                style: AppText.label,
              ),
              childrenPadding: const EdgeInsets.only(bottom: 8),
              children: [
                PoemView(
                  poem: poem,
                  showLineNumbers: true,
                  evidenceLines: evidenceLines.toSet(),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 2 · 3. 전문가 해석 A · B — 항상 전부
            if (experts.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(AppStrings.comparisonNoExperts,
                    style: AppText.bodySub),
              ),
            for (var i = 0; i < experts.length; i++) ...[
              _ExpertCard(
                expert: experts[i],
                comparison: i < comparisons.length ? comparisons[i] : null,
              ),
              const SizedBox(height: 14),
            ],

            // 4. 창작 배경 · 다른 사람의 대화
            const SizedBox(height: 12),
            AppSecondaryButton(
              label: AppStrings.comparisonCreationBackground,
              icon: Icons.history_edu_outlined,
              onPressed: () => _showCreationBackground(context, poem),
            ),
            const SizedBox(height: 10),
            AppPrimaryButton(
              label: AppStrings.comparisonGoCommunity,
              onPressed: () => AppRouter.goToTab(context, AppRoutes.community),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpertCard extends StatelessWidget {
  const _ExpertCard({required this.expert, required this.comparison});

  final ExpertInterpretation expert;
  final FakeComparison? comparison;

  String _relationText(FakeComparison comparison) =>
      switch (comparison.relation) {
        Relation.sameLines => AppStrings.comparisonRelationSameLines,
        Relation.partialOverlap => AppStrings.comparisonRelationPartialOverlap,
        Relation.differentLines =>
          AppStrings.comparisonRelationDifferentLines(comparison.centerLine),
      };

  @override
  Widget build(BuildContext context) {
    final result = comparison;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(expert.label),
          Text(expert.stance, style: AppText.bodyStrong),
          if (result != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.compare_arrows_rounded,
                    size: 18, color: AppColors.info),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(_relationText(result), style: AppText.relation),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(result.comparisonText, style: AppText.bodySub),
          ],
          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: 10),
          for (final claim in expert.claims)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 64,
                    child: Text(
                      claim.lines.map(AppStrings.lineLabel).join(' · '),
                      style: AppText.caption,
                    ),
                  ),
                  Expanded(child: Text(claim.point, style: AppText.body)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _LineChip extends StatelessWidget {
  const _LineChip({required this.lineNo});

  final int lineNo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.confirmed),
      ),
      child: Text(
        AppStrings.lineLabel(lineNo),
        style: AppText.caption.copyWith(color: AppColors.confirmed),
      ),
    );
  }
}
