// S08 대화 목록 — 주인: D
// 시 선택 칩 (해석을 저장하지 않은 시는 자물쇠), 대화 카드 (닉네임 · 첫 낱말 · 요약).
// 정렬은 최신순 — 공감 수로 정렬하지 않는다.
// 1단계: 잠금은 표시만 하고 늘 열어둔다. 열람 조건은 2단계(보안 규칙).
import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../data/fakes/fake_data.dart';
import '../../data/models/public_conversation.dart';
import '../../shared/widgets/app_card.dart';

class CommunityListScreen extends StatefulWidget {
  const CommunityListScreen({super.key});

  @override
  State<CommunityListScreen> createState() => _CommunityListScreenState();
}

class _CommunityListScreenState extends State<CommunityListScreen> {
  String _selectedPoemId = FakeData.todayPoemId;

  @override
  Widget build(BuildContext context) {
    final conversations = FakeData.conversationsFor(_selectedPoemId);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.communityTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          const Text(AppStrings.communityGuide, style: AppText.bodySub),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final poem in FakeData.poems) ...[
                  ChoiceChip(
                    label: Text(poem.title),
                    avatar: (FakeData.readingFor(poem.poemId)?.isSaved ?? false)
                        ? null
                        : const Icon(Icons.lock_outline,
                            size: 16, color: AppColors.textFaint),
                    showCheckmark: false,
                    selected: poem.poemId == _selectedPoemId,
                    onSelected: (_) =>
                        setState(() => _selectedPoemId = poem.poemId),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (conversations.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Text(AppStrings.communityEmpty, style: AppText.bodySub),
              ),
            ),
          for (final conversation in conversations) ...[
            _ConversationCard(conversation: conversation),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _ConversationCard extends StatelessWidget {
  const _ConversationCard({required this.conversation});

  final PublicConversation conversation;

  @override
  Widget build(BuildContext context) {
    final author = FakeData.profileById(conversation.userId);

    return AppCard(
      onTap: () => Navigator.of(context).pushNamed(
        AppRoutes.communityDetail(conversation.conversationId),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(author.nickname, style: AppText.bodyStrong)),
              Text(
                AppStrings.communityFirstWord(conversation.firstWord),
                style: AppText.caption.copyWith(color: AppColors.accent),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            conversation.summary,
            style: AppText.bodySub,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
