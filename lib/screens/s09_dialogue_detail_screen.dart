import 'package:flutter/material.dart';
import '../core/data/mock_data.dart';
import '../core/theme/app_colors.dart';
import '../models/community_post.dart';
import 's12_profile_screen.dart';

/// S09 대화 보기 화면
/// - 한 사람의 첫 낱말 ➔ 대화 요약 ➔ 최종 해석
/// - 닉네임 탭 시 S12 남의 프로필로 이동
/// - 공감 버튼 (정렬/순위에 쓰이지 않음)
class S09DialogueDetailScreen extends StatefulWidget {
  final CommunityPost post;

  const S09DialogueDetailScreen({
    super.key,
    required this.post,
  });

  @override
  State<S09DialogueDetailScreen> createState() => _S09DialogueDetailScreenState();
}

class _S09DialogueDetailScreenState extends State<S09DialogueDetailScreen> {
  late bool _isEmpathized;
  late int _empathyCount;

  @override
  void initState() {
    super.initState();
    _isEmpathized = widget.post.isEmpathized;
    _empathyCount = widget.post.empathyCount;
  }

  void _toggleEmpathy() {
    setState(() {
      _isEmpathized = !_isEmpathized;
      if (_isEmpathized) {
        _empathyCount++;
      } else {
        _empathyCount--;
      }
      widget.post.isEmpathized = _isEmpathized;
      widget.post.empathyCount = _empathyCount;
    });
  }

  void _navigateToAuthorProfile() {
    final authorProfile = MockData.otherProfiles[widget.post.authorUid];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => S12ProfileScreen(
          profile: authorProfile,
          isMe: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          '${post.poemTitle} · 읽은이의 대화',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 작성자 정보 카드 (닉네임 클릭 가능)
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
                    backgroundColor: AppColors.userBubbleBackground,
                    child: Text(
                      post.authorNickname.characters.first,
                      style: const TextStyle(
                        color: AppColors.accentWine,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _navigateToAuthorProfile,
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Text(
                              post.authorNickname,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.chevron_right,
                              size: 18,
                              color: AppColors.textMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Text(
                    '${post.createdAt.month}월 ${post.createdAt.day}일',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 1. 첫 낱말 (대화의 출발점)
            _buildSectionHeader('1. 첫 낱말', '시를 읽고 가장 먼저 떠올린 말'),
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.userBubbleBackground,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      post.firstWord,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentWine,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    '이 낱말에서 AI와의 대화가 시작되었습니다.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. 대화 요약 & 근거 구절
            _buildSectionHeader('2. 대화 과정', 'AI 질문과 사유의 요약'),
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
                    post.aiSummary,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.inputBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 16,
                          color: AppColors.confirmedGreen,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '확인된 근거 구절: ${post.groundedLines.map((l) => '$l행').join(', ')}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.confirmedGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. 최종 해석
            _buildSectionHeader('3. 최종 해석', '대화를 거쳐 도달한 고유한 생각'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.userBubbleBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.accentWine.withValues(alpha: 0.3)),
              ),
              child: Text(
                post.finalInterpretation,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.7,
                  fontFamily: 'NanumMyeongjo',
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // 하단: 공감 버튼 (정렬에 쓰이지 않는 순수한 공감)
            Center(
              child: OutlinedButton.icon(
                onPressed: _toggleEmpathy,
                icon: Icon(
                  _isEmpathized ? Icons.favorite : Icons.favorite_border,
                  size: 20,
                  color: _isEmpathized ? AppColors.accentWine : AppColors.textSecondary,
                ),
                label: Text(
                  '공감 $_empathyCount',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _isEmpathized ? AppColors.accentWine : AppColors.textSecondary,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: _isEmpathized ? AppColors.userBubbleBackground : AppColors.card,
                  side: BorderSide(
                    color: _isEmpathized ? AppColors.accentWine : AppColors.border,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Center(
              child: Text(
                '공감은 우열이나 순위에 반영되지 않습니다.',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
