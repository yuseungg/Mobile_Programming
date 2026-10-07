// S07 대조 — 주인: D
// D의 part-d `S07ComparisonScreen`을 이름만 맞춰 옮겼다 (docs/여백-이름대조표.md).
// - 순서: 내 해석 → 전문가 해석 A → 전문가 해석 B (기획서 4장)
// - 관계는 코드가 근거 행을 대조해 계산 (lib/compare/relation.dart)
// - 창작 배경 보기 (바텀시트) · 다른 사람의 대화 보기 (S08 탭)
// - 해석 본문은 주장(claims)으로 그린다. part-d의 fullText는 용어 사전에 없어 뺐다
import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../compare/relation.dart';
import '../../data/fakes/fake_data.dart';
import '../../data/models/expert_interpretation.dart';
import '../../data/models/poem.dart';

class ComparisonScreen extends StatelessWidget {
  const ComparisonScreen({super.key, required this.poemId});

  final String poemId;

  String _relationText(Relation relation, ExpertInterpretation expert) =>
      switch (relation) {
        Relation.sameLines => AppStrings.comparisonRelationSameLines,
        Relation.partialOverlap => AppStrings.comparisonRelationPartialOverlap,
        Relation.differentLines =>
          AppStrings.comparisonRelationDifferentLines(expertLines(expert)),
      };

  void _showCreationBackground(BuildContext context, Poem poem) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      showDragHandle: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                AppStrings.comparisonCreationBackgroundTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                  fontFamily: AppFonts.myeongjo,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                poem.creationBackground,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: AppColors.textSub,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.input,
                    foregroundColor: AppColors.text,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(AppStrings.close),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final poem = FakeData.poemById(poemId);
    final reading = FakeData.readingFor(poemId);
    final myInterpretation = reading?.interpretation ?? '';
    final myEvidenceLines = reading?.evidenceLines ?? const <int>[];
    final experts = FakeData.expertInterpretations[poemId] ?? const [];
    final comparisonTexts = FakeData.comparisonTexts[poemId] ?? const [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppStrings.comparisonTitle(poem.title),
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.text),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 시 정보 카드
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.input,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.menu_book_outlined,
                      size: 18, color: AppColors.textSub),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppStrings.comparisonPoemInfo(
                          poem.title, poem.author, poem.year),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSub,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    AppStrings.comparisonMyEvidence(myEvidenceLines),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.confirmed,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 1. 내 해석 (가장 위, 가장 무겁게)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.accentBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          AppStrings.comparisonMine,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.card,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        AppStrings.comparisonMineCaption,
                        style:
                            TextStyle(fontSize: 12, color: AppColors.textFaint),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    myInterpretation,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: AppColors.text,
                      fontFamily: AppFonts.myeongjo,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. 전문가 해석 — 항상 전부 (관계는 코드가 계산)
            if (experts.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Text(
                  AppStrings.comparisonNoExperts,
                  style: TextStyle(color: AppColors.textSub),
                ),
              ),
            for (var i = 0; i < experts.length; i++)
              _ExpertCard(
                expert: experts[i],
                relationText: _relationText(
                  computeRelation(myEvidenceLines, experts[i]),
                  experts[i],
                ),
                comparisonText:
                    i < comparisonTexts.length ? comparisonTexts[i] : null,
              ),

            const SizedBox(height: 12),

            // (1) 창작 배경 보기 (바텀시트)
            OutlinedButton.icon(
              onPressed: () => _showCreationBackground(context, poem),
              icon: const Icon(Icons.history_edu_outlined, size: 18),
              label: const Text(AppStrings.comparisonCreationBackground),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.text,
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // (2) 다른 사람의 대화 보기 (S08 탭)
            ElevatedButton.icon(
              onPressed: () => AppRouter.goToTab(context, AppRoutes.community),
              icon: const Icon(Icons.people_outline, size: 18),
              label: const Text(AppStrings.comparisonGoCommunity),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.card,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _ExpertCard extends StatelessWidget {
  const _ExpertCard({
    required this.expert,
    required this.relationText,
    required this.comparisonText,
  });

  final ExpertInterpretation expert;
  final String relationText;
  final String? comparisonText;

  @override
  Widget build(BuildContext context) {
    final comparison = comparisonText;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.text.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 전문가 라벨 & 코드가 계산한 관계 한 줄
          Row(
            children: [
              Text(
                expert.label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSub,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.confirmed.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    relationText,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.confirmed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 입장 (stance)
          Text(
            expert.stance,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.info,
            ),
          ),
          if (comparison != null) ...[
            const SizedBox(height: 10),
            // 비교 문장 (2단계에 비교 모델이 작성, 공통점부터)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.input,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                comparison,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.text,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          // 전문가 해석 본문 — 주장마다 근거 행과 함께
          for (final claim in expert.claims)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 64,
                    child: Text(
                      AppStrings.lineList(claim.lines),
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.6,
                        color: AppColors.textFaint,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      claim.point,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: AppColors.textSub,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
