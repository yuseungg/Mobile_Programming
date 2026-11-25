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
import '../../shared/widgets/app_loading.dart';
import '../../writers/comparison_writer.dart';
import '../../writers/fake_comparison_writer.dart';
import '../../writers/openrouter_comparison_writer.dart';
import '../../shared/widgets/language_toggle.dart';

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

  /// 비교 문장을 쓰는 쪽. 비워 두면 키가 있을 때 모델이 쓰고(OpenRouter),
  /// 키가 없거나 호출이 실패하면 미리 쓴 문장과 관계 한 줄로 채운다.
  /// 테스트는 여기에 정해진 문장을 쓰는 구현을 끼운다.
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
    // 시 원문은 비교 문장을 쓰는 쪽도 쓴다 (인용이 원문에 있는지 확인한다)
    final poem = await source.poemById(poemId);

    // 미리 쓴 문장은 폴백의 재료다. 모델이 쓰면 그것이 이긴다.
    final prewritten = FakeComparisonWriter(
      prewritten: {poemId: await source.comparisonTextsFor(poemId)},
    );
    final writer =
        widget.writer ?? await createComparisonWriter(fallback: prewritten);

    final comparisons = <ComparisonText>[];
    for (var i = 0; i < experts.length; i++) {
      comparisons.add(
        await writer.write(
          ComparisonRequest(
            poem: poem,
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
      poem: poem,
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
              Text(
                AppStrings.comparisonCreationBackgroundTitle,
                style: AppText.poemTitleSmall,
              ),
              const SizedBox(height: 12),
              Text(
                poem.creationBackground,
                style: AppText.body.copyWith(color: AppColors.textSub),
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
                  child: Text(AppStrings.close),
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
            appBar: LanguageToggleAppBar(),
            body: Center(child: UnavailableNotice()),
          );
        }
        if (data == null) {
          // 저장을 누르고 여기가 열리기까지가 이 앱에서 가장 긴 기다림이다 —
          // 저장소 쓰기(markComparisonOpened)가 끝나고, 그 위에 모델이 비교
          // 문장을 쓴다. 스피너로는 멈춘 것과 구분이 되지 않아 로딩 화면을 쓴다.
          // 시 제목은 아직 읽히지 않았으므로 제목 없이 띄운다 — 그래도 오른쪽
          // 위 KR / EN 토글은 LoadingPage가 붙여 준다.
          return LoadingPage(
            message: AppStrings.loadingSavingConversation,
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
      appBar: AppBar(
        title: Text(AppStrings.comparisonTitle(poem.title)),
        actions: const [LanguageToggle()],
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
                      style: AppText.label,
                    ),
                  ),
                  // 근거 행이 없으면 「내 근거:」만 덩그러니 남는다 — 아예 뺀다.
                  // S05에서 시를 인용하지 않고 대화를 마치면 실제로 빈다.
                  if (myEvidenceLines.isNotEmpty)
                    Text(
                      AppStrings.comparisonMyEvidence(myEvidenceLines),
                      style: AppText.evidenceTag,
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
                        child: Text(
                          AppStrings.comparisonMine,
                          style: AppText.tagOnAccent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Expanded가 없으면 좁은 화면에서 줄바꿈을 못 해 넘친다.
                      // 320픽셀 폭에서 27픽셀이 잘렸다 (태블릿에서는 안 보인다).
                      // 문구가 KR / EN을 따라 바뀌므로 const가 아니다 (#55).
                      Expanded(
                        child: Text(
                          AppStrings.comparisonMineCaption,
                          style: AppText.caption,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    myInterpretation,
                    style: AppText.interpretationSmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. 전문가 해석 — 항상 전부 (관계는 코드가 계산)
            if (experts.isEmpty)
              Padding(
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
              label: Text(AppStrings.comparisonCreationBackground),
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
              label: Text(AppStrings.comparisonGoCommunity),
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
                style: AppText.label.copyWith(fontWeight: FontWeight.w700),
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
                style: AppText.caption.copyWith(fontSize: 13, color: AppColors.text),
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
                  // 한 줄로 이어 쓰면 칸을 넘칠 때 한글이 글자 단위로 끊겨
                  // 「8」과 「행」이 갈라진다 (태블릿 점검에서 나왔다).
                  // 행마다 따로 그려서 Wrap이 행 사이에서만 줄을 바꾸게 한다.
                  SizedBox(
                    width: 72,
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 2,
                      children: [
                        for (final lineNo in claim.lines)
                          Text(
                            AppStrings.lineLabel(lineNo),
                            style: AppText.caption,
                          ),
                      ],
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
