// S09 대화 보기 — 주인: D
// D의 part-d `S09DialogueDetailScreen`을 이름만 맞춰 옮겼다 (docs/여백-이름대조표.md).
// - 한 사람의 첫 낱말 → 대화 요약 → 최종 해석
// - 닉네임 탭 → S12 남의 프로필
// - 공감 버튼 (정렬·순위에 쓰지 않음). 1단계는 화면 안에서만 바뀐다
import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../data/fakes/fake_data.dart';

class CommunityDetailScreen extends StatefulWidget {
  const CommunityDetailScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen> {
  late final _conversation = FakeData.conversationById(widget.conversationId);
  bool _hasEmpathized = false;
  late int _empathyCount = _conversation.empathyCount;

  void _toggleEmpathy() {
    setState(() {
      _hasEmpathized = !_hasEmpathized;
      _empathyCount += _hasEmpathized ? 1 : -1;
    });
  }

  void _openAuthorProfile() {
    Navigator.of(context).pushNamed(AppRoutes.profile(_conversation.userId));
  }

  @override
  Widget build(BuildContext context) {
    final conversation = _conversation;
    final poem = FakeData.poemById(conversation.poemId);
    final author = FakeData.profileById(conversation.userId);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppStrings.communityDetailTitle(poem.title),
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
            // 작성자 정보 카드 (닉네임 누르면 프로필)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.accentBg,
                    child: Text(
                      author.nickname.characters.first,
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _openAuthorProfile,
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Text(
                              author.nickname,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.text,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.chevron_right,
                              size: 18,
                              color: AppColors.textFaint,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Text(
                    AppStrings.monthDay(conversation.createdAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textFaint,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 1. 첫 낱말 (대화의 출발점)
            const _SectionHeader(
              title: AppStrings.communityDetailFirstWord,
              subtitle: AppStrings.communityDetailFirstWordCaption,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accentBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      conversation.firstWord,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      AppStrings.communityDetailFirstWordNote,
                      style: TextStyle(fontSize: 13, color: AppColors.textSub),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. 대화 요약 & 근거 구절
            const _SectionHeader(
              title: AppStrings.communityDetailSummary,
              subtitle: AppStrings.communityDetailSummaryCaption,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation.summary,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: AppColors.text,
                    ),
                  ),
                  if (conversation.evidenceLines.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.input,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            size: 16,
                            color: AppColors.confirmed,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppStrings.communityDetailEvidence(
                                conversation.evidenceLines),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.confirmed,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. 최종 해석
            const _SectionHeader(
              title: AppStrings.communityDetailInterpretation,
              subtitle: AppStrings.communityDetailInterpretationCaption,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.accentBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.3)),
              ),
              child: Text(
                conversation.interpretation,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.7,
                  fontFamily: AppFonts.myeongjo,
                  color: AppColors.text,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // 공감 버튼 (정렬에 쓰이지 않는 순수한 공감)
            Center(
              child: OutlinedButton.icon(
                onPressed: _toggleEmpathy,
                icon: Icon(
                  _hasEmpathized ? Icons.favorite : Icons.favorite_border,
                  size: 20,
                  color: _hasEmpathized ? AppColors.accent : AppColors.textSub,
                ),
                label: Text(
                  AppStrings.communityDetailEmpathyCount(_empathyCount),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color:
                        _hasEmpathized ? AppColors.accent : AppColors.textSub,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  backgroundColor:
                      _hasEmpathized ? AppColors.accentBg : AppColors.card,
                  side: BorderSide(
                    color: _hasEmpathized ? AppColors.accent : AppColors.border,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Center(
              child: Text(
                AppStrings.communityDetailEmpathyNote,
                style: TextStyle(fontSize: 11, color: AppColors.textFaint),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: AppColors.textFaint),
          ),
        ),
      ],
    );
  }
}
