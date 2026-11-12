// S07 대조 — 주인: D
// D의 part-d `S07ComparisonScreen`을 이름만 맞춰 옮겼다 (docs/여백-이름대조표.md).
// - 순서: 내 해석 → 전문가 해석 A → 전문가 해석 B (기획서 4장)
// - 관계는 코드가 근거 행을 대조해 계산 (lib/compare/relation.dart)
// - 창작 배경 보기 (바텀시트) · 다른 사람의 대화 보기 (S08 탭)
// - 해석 본문은 주장(claims)으로 그린다. part-d의 fullText는 용어 사전에 없어 뺐다
import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../app/strings.dart';
import '../community/locked_notice.dart';
import '../../app/theme.dart';
import '../../compare/relation.dart';
import '../../data/models/expert_interpretation.dart';
import '../../data/models/poem.dart';
import '../../ports/repository_reading_source.dart';
import '../../ports/reading_source.dart';
import '../../writers/comparison_writer.dart';
import '../../writers/fake_comparison_writer.dart';

/// 화면 한 번에 필요한 것
class _ComparisonData {
  const _ComparisonData({
    required this.poem,
    required this.myInterpretation,
    required this.myEvidenceLines,
    required this.experts,
    required this.comparisons,
  });

  final Poem poem;
  final String myInterpretation;
  final List<int> myEvidenceLines;
  final List<ExpertInterpretation> experts;

  /// 전문가 해석과 같은 순서. 모델이 못 썼으면 isFallback이 참이다.
  final List<ComparisonText> comparisons;
}

class ComparisonScreen extends StatefulWidget {
  const ComparisonScreen({
    super.key,
    required this.poemId,
    this.source = const RepositoryReadingSource(),
    this.writer,
  });

  final String poemId;
  final ReadingSource source;

  /// 비교 문장을 쓰는 쪽. 비워 두면 미리 쓴 문장과 관계 한 줄로 채운다.
  /// A의 PR이 병합되면 OpenRouter를 쓰는 구현체를 여기에 넣는다.
  final ComparisonWriter? writer;

  @override
  State<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen> {
  late final Future<_ComparisonData> _data = _load();

  Future<_ComparisonData> _load() async {
    final source = widget.source;
    final poemId = widget.poemId;
    final reading = await source.readingFor(poemId);
    // 대조를 본 뒤에는 해석을 고칠 수 없다 (기획서 4장) — 그 잠금을 여기서 건다
    await source.markComparisonOpened(poemId);
    final myInterpretation = reading?.interpretation ?? '';
    final myEvidenceLines = reading?.evidenceLines ?? const <int>[];
    final experts = await source.expertsFor(poemId);

    // 미리 쓴 문장은 폴백의 재료다. 모델이 쓰면 그것이 이긴다.
    final writer = widget.writer ??
        FakeComparisonWriter(
          prewritten: {poemId: await source.comparisonTextsFor(poemId)},
        );

    final comparisons = <ComparisonText>[];
    for (var i = 0; i < experts.length; i++) {
      comparisons.add(
        await writer.write(
          ComparisonRequest(
            poemId: poemId,
            myInterpretation: myInterpretation,
            myEvidenceLines: myEvidenceLines,
            expert: experts[i],
            relation: computeRelation(myEvidenceLines, experts[i]),
            expertIndex: i,
          ),
        ),
      );
    }

    return _ComparisonData(
      poem: await source.poemById(poemId),
      myInterpretation: myInterpretation,
      myEvidenceLines: myEvidenceLines,
      experts: experts,
      comparisons: comparisons,
    );
  }

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
                style: AppText.poemTitleSmall,
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
    return FutureBuilder<_ComparisonData>(
      future: _data,
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (snapshot.hasError) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: UnavailableNotice()),
          );
        }
        if (data == null) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return _content(context, data);
      },
    );
  }

  Widget _content(BuildContext context, _ComparisonData data) {
    final poem = data.poem;
    final myInterpretation = data.myInterpretation;
    final myEvidenceLines = data.myEvidenceLines;
    final experts = data.experts;
    final comparisons = data.comparisons;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(AppStrings.comparisonTitle(poem.title))),
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
                      style: AppText.label,
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
                            AppText.caption,
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
                  style: AppText.bodySub,
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
                    i < comparisons.length ? comparisons[i].text : null,
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
                    color: AppColors.info.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  // 관계는 세 가지 모두 같은 색이다. 겹쳤다고 초록(confirmed)을
                  // 쓰면 「맞췄다」로 읽힌다 — 기획서 4장은 어느 해석도 정답이
                  // 아니라고 못박는다. A가 준비해 둔 AppText.relation을 쓴다.
                  child: Text(relationText, style: AppText.relation),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 입장 (stance)
          Text(
            expert.stance,
            style: AppText.relation,
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
                      style: AppText.caption,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      claim.point,
                      style: AppText.bodySub,
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
