// S09 대화 보기 — 주인: D
// D의 part-d `S09DialogueDetailScreen`을 이름만 맞춰 옮겼다 (docs/여백-이름대조표.md).
// - 한 사람의 첫 낱말 → 대화 요약 → 최종 해석
// - 닉네임 탭 → S12 남의 프로필
// - 공감 버튼 (정렬·순위에 쓰지 않음). 1단계는 화면 안에서만 바뀐다
// - 그 시의 해석을 저장하지 않았으면 내용 대신 잠금 안내 (기획서 5장)
import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../data/models/poem.dart';
import '../../data/models/public_conversation.dart';
import '../../data/models/user_profile.dart';
import '../../ports/fake_reading_source.dart';
import '../../ports/reading_source.dart';
import '../../writers/fake_summary_writer.dart';
import '../../writers/summary_writer.dart';
import 'locked_notice.dart';

/// 화면 한 번에 필요한 것
class _DetailData {
  const _DetailData({
    required this.conversation,
    required this.poem,
    required this.author,
    required this.summary,
    required this.isLocked,
  });

  final PublicConversation conversation;
  final Poem poem;
  final UserProfile author;

  /// 공개 대화에 담긴 요약. 비어 있으면 폴백으로 채운다.
  final String summary;

  /// 그 시의 해석을 저장했을 때만 남의 대화를 볼 수 있다 (기획서 5장).
  /// 화면 분기는 우회할 수 있어, 실제 차단은 C의 보안 규칙이 맡는다.
  final bool isLocked;
}

class CommunityDetailScreen extends StatefulWidget {
  const CommunityDetailScreen({
    super.key,
    required this.conversationId,
    this.source = const FakeReadingSource(),
    this.summaryWriter = const FakeSummaryWriter(),
  });

  final String conversationId;
  final ReadingSource source;

  /// 저장할 때 요약이 비어 있었으면 이것으로 채운다. A의 PR이 병합되면
  /// OpenRouter를 쓰는 구현체로 바꾼다.
  final SummaryWriter summaryWriter;

  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen> {
  late final Future<_DetailData> _data = _load();
  bool _hasEmpathized = false;
  int? _empathyCount; // 읽어 온 뒤에 정해진다

  Future<_DetailData> _load() async {
    final source = widget.source;
    final conversation = await source.conversationById(widget.conversationId);
    final reading = await source.readingFor(conversation.poemId);
    return _DetailData(
      conversation: conversation,
      poem: await source.poemById(conversation.poemId),
      author: await source.profileById(conversation.userId),
      summary: await _summaryOf(conversation),
      isLocked: !(reading?.isSaved ?? false),
    );
  }

  /// 요약은 저장할 때 한 번 쓰여 문서에 담긴다. 화면이 열릴 때마다 모델을
  /// 부르지 않는다. 그때 못 썼으면(키 없음·실패) 여기서 사실만으로 채운다.
  Future<String> _summaryOf(PublicConversation conversation) async {
    if (conversation.summary.trim().isNotEmpty) return conversation.summary;
    final written = await widget.summaryWriter.write(
      SummaryRequest(
        poemId: conversation.poemId,
        firstWord: conversation.firstWord,
        conversation: const [], // 공개 문서에는 대화 원본이 없다
        interpretation: conversation.interpretation,
      ),
    );
    return written.text;
  }

  void _toggleEmpathy(int baseCount) {
    setState(() {
      _hasEmpathized = !_hasEmpathized;
      _empathyCount = baseCount + (_hasEmpathized ? 1 : 0);
    });
  }

  void _openAuthorProfile(String userId) {
    Navigator.of(context).pushNamed(AppRoutes.profile(userId));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DetailData>(
      future: _data,
      builder: (context, snapshot) {
        final data = snapshot.data;
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

  Widget _content(BuildContext context, _DetailData data) {
    final conversation = data.conversation;
    final poem = data.poem;
    final author = data.author;
    final empathyCount = _empathyCount ?? conversation.empathyCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppStrings.communityDetailTitle(poem.title)),
      ),
      body: data.isLocked
          ? LockedNotice(poemId: conversation.poemId)
          : SingleChildScrollView(
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
                      onTap: () => _openAuthorProfile(author.userId),
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
                    style: AppText.caption,
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
                    data.summary,
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
                onPressed: () =>
                    _toggleEmpathy(conversation.empathyCount),
                icon: Icon(
                  _hasEmpathized ? Icons.favorite : Icons.favorite_border,
                  size: 20,
                  color: _hasEmpathized ? AppColors.accent : AppColors.textSub,
                ),
                label: Text(
                  AppStrings.communityDetailEmpathyCount(empathyCount),
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
                style: AppText.lineNumber,
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
            style: AppText.caption,
          ),
        ),
      ],
    );
  }
}
