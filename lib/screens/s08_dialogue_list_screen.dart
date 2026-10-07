import 'package:flutter/material.dart';
import '../core/data/mock_data.dart';
import '../core/theme/app_colors.dart';
import '../models/community_post.dart';
import 's09_dialogue_detail_screen.dart';

/// S08 대화 목록 화면
/// - 이 시를 읽은 사람들이 공개한 대화 목록
/// - 카드 탭 시 S09 대화 보기로 이동
/// - 하단 탭바 화면(S03, S08, S10) 중 하나
class S08DialogueListScreen extends StatelessWidget {
  final String poemId;
  final String poemTitle;

  const S08DialogueListScreen({
    super.key,
    this.poemId = 'seosi',
    this.poemTitle = '서시',
  });

  @override
  Widget build(BuildContext context) {
    // 해당 시에 해당하는 글 필터링 (MockData)
    final posts = MockData.communityPosts
        .where((post) => post.poemId == poemId)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          '$poemTitle · 모두의 대화',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          return _CommunityPostCard(
            post: post,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => S09DialogueDetailScreen(post: post),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _CommunityPostCard extends StatelessWidget {
  final CommunityPost post;
  final VoidCallback onTap;

  const _CommunityPostCard({
    required this.post,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
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
                      post.authorNickname,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.userBubbleBackground,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '#${post.firstWord}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.accentWine,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // 공감 수
                    Row(
                      children: [
                        const Icon(
                          Icons.favorite_border,
                          size: 15,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${post.empathyCount}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // AI 요약 미리보기
                Text(
                  post.aiSummary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),

                // 최종 해석 인용
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border(
                      left: BorderSide(color: AppColors.accentWine, width: 3),
                    ),
                  ),
                  child: Text(
                    post.finalInterpretation,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      fontFamily: 'NanumMyeongjo',
                      color: AppColors.textPrimary,
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
