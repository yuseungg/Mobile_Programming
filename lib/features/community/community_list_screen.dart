// S08 대화 목록 — 주인: D
// D의 part-d `S08DialogueListScreen`을 이름만 맞춰 옮겼다 (docs/여백-이름대조표.md).
// - 이 시를 읽은 사람들이 공개한 대화 목록 (최신순, 공감 수로 정렬하지 않음)
// - 카드 탭 → S09
// - 하단 탭 화면이라 시는 위의 칩으로 고른다 (해석을 저장하지 않은 시는 자물쇠)
// - 1단계: 잠금은 표시만 하고 늘 열어둔다
import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../data/fakes/fake_data.dart';
import '../../data/models/public_conversation.dart';

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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          AppStrings.communityTitle,
          style: TextStyle(
            color: AppColors.text,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.text),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
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
          const SizedBox(height: 16),
          if (conversations.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Text(
                  AppStrings.communityEmpty,
                  style: TextStyle(color: AppColors.textSub),
                ),
              ),
            ),
          for (final conversation in conversations)
            _ConversationCard(
              conversation: conversation,
              onTap: () => Navigator.of(context).pushNamed(
                AppRoutes.communityDetail(conversation.conversationId),
              ),
            ),
        ],
      ),
    );
  }
}

class _ConversationCard extends StatelessWidget {
  const _ConversationCard({required this.conversation, required this.onTap});

  final PublicConversation conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final author = FakeData.profileById(conversation.userId);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.text.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 작성자 닉네임 & 첫 낱말 칩
                Row(
                  children: [
                    Text(
                      author.nickname,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.accentBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        AppStrings.communityFirstWordTag(
                            conversation.firstWord),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // 공감 수
                    const Icon(
                      Icons.favorite_border,
                      size: 15,
                      color: AppColors.textFaint,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${conversation.empathyCount}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textFaint,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // AI 요약 미리보기
                Text(
                  conversation.summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.textSub,
                  ),
                ),
                const SizedBox(height: 12),

                // 최종 해석 인용
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: const BoxDecoration(
                    color: AppColors.input,
                    border: Border(
                      left: BorderSide(color: AppColors.accent, width: 3),
                    ),
                  ),
                  child: Text(
                    conversation.interpretation,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      fontFamily: AppFonts.myeongjo,
                      color: AppColors.text,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
