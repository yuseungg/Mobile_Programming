// S09 대화 보기 — 주인: D
// 한 사람의 첫 낱말 → 대화 요약 → 최종 해석, 공감. 닉네임을 누르면 그 사람의 프로필(S12).
// 1단계: 공감 버튼은 아무 일도 하지 않는다.
import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../data/fakes/fake_data.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/section_label.dart';

class CommunityDetailScreen extends StatelessWidget {
  const CommunityDetailScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  Widget build(BuildContext context) {
    final conversation = FakeData.conversationById(conversationId);
    final poem = FakeData.poemById(conversation.poemId);
    final author = FakeData.profileById(conversation.userId);

    return Scaffold(
      appBar: AppBar(title: Text(poem.title, style: AppText.screenTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            // 작성자 — 누르면 프로필
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.of(context)
                  .pushNamed(AppRoutes.profile(author.userId)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.account_circle_outlined,
                        size: 32, color: AppColors.textSub),
                    const SizedBox(width: 10),
                    Text(author.nickname, style: AppText.bodyStrong),
                    const Icon(Icons.chevron_right,
                        color: AppColors.textFaint),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const SectionLabel(AppStrings.communityDetailFirstWord),
            Text(conversation.firstWord, style: AppText.firstWord),
            const SizedBox(height: 28),
            const SectionLabel(AppStrings.communityDetailSummary),
            Text(conversation.summary, style: AppText.body),
            const SizedBox(height: 28),
            const SectionLabel(AppStrings.communityDetailInterpretation),
            AppCard(
              child: Text(
                conversation.interpretation,
                style: AppText.interpretation,
              ),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                ),
                onPressed: () {},
                icon: const Icon(Icons.favorite_border_rounded,
                    size: 18, color: AppColors.accent),
                label: Text(
                  AppStrings.communityDetailEmpathyCount(
                    conversation.empathyCount,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
