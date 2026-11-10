// S08 대화 목록 — 주인: D
// D의 part-d `S08DialogueListScreen`을 이름만 맞춰 옮겼다 (docs/여백-이름대조표.md).
// - 이 시를 읽은 사람들이 공개한 대화 목록 (최신순, 공감 수로 정렬하지 않음)
// - 카드 탭 → S09
// - 하단 탭 화면이라 시는 위의 칩으로 고른다 (해석을 저장하지 않은 시는 자물쇠)
// - 저장하지 않은 시를 고르면 목록 대신 잠금 안내를 보여 준다 (기획서 5장)
import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../data/models/poem.dart';
import '../../data/models/public_conversation.dart';
import '../../ports/fake_reading_source.dart';
import '../../ports/reading_source.dart';
import 'locked_notice.dart';

/// 시 칩 줄에 필요한 것 — 한 번만 읽는다
class _ShellData {
  const _ShellData({required this.poems, required this.unlocked});

  final List<Poem> poems;
  final Map<String, bool> unlocked; // poemId → 그 시의 해석을 저장했는가
}

/// 고른 시의 목록에 필요한 것 — 시를 바꿀 때마다 다시 읽는다
class _ListData {
  const _ListData({
    required this.isUnlocked,
    required this.conversations,
    required this.nicknames,
  });

  final bool isUnlocked;
  final List<PublicConversation> conversations;

  /// uid → 닉네임. 카드마다 읽지 않도록 미리 모아 둔다 (같은 uid는 한 번만).
  /// 진짜 해결은 C가 공개 대화 문서에 닉네임을 비정규화해 넣는 것이다.
  final Map<String, String> nicknames;
}

class CommunityListScreen extends StatefulWidget {
  const CommunityListScreen({
    super.key,
    this.source = const FakeReadingSource(),
  });

  final ReadingSource source;

  @override
  State<CommunityListScreen> createState() => _CommunityListScreenState();
}

class _CommunityListScreenState extends State<CommunityListScreen> {
  late final ReadingSource _source = widget.source;
  late String _selectedPoemId = _source.todayPoemId;
  late final Future<_ShellData> _shell = _loadShell();
  late Future<_ListData> _list = _loadList(_selectedPoemId);

  Future<_ShellData> _loadShell() async {
    final poems = await _source.poems();
    final unlocked = <String, bool>{};
    for (final poem in poems) {
      unlocked[poem.poemId] = await _isUnlocked(poem.poemId);
    }
    return _ShellData(poems: poems, unlocked: unlocked);
  }

  /// 그 시의 해석을 저장했는가 — 유일한 잠금 해제 지점 (기획서 5장)
  Future<bool> _isUnlocked(String poemId) async =>
      (await _source.readingFor(poemId))?.isSaved ?? false;

  Future<_ListData> _loadList(String poemId) async {
    if (!await _isUnlocked(poemId)) {
      return const _ListData(
        isUnlocked: false,
        conversations: [],
        nicknames: {},
      );
    }
    final conversations = await _source.conversationsFor(poemId);
    final nicknames = <String, String>{};
    for (final conversation in conversations) {
      if (nicknames.containsKey(conversation.userId)) continue;
      nicknames[conversation.userId] =
          (await _source.profileById(conversation.userId)).nickname;
    }
    return _ListData(
      isUnlocked: true,
      conversations: conversations,
      nicknames: nicknames,
    );
  }

  void _select(String poemId) {
    setState(() {
      _selectedPoemId = poemId;
      _list = _loadList(poemId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text(AppStrings.communityTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          FutureBuilder<_ShellData>(
            future: _shell,
            builder: (context, snapshot) {
              final shell = snapshot.data;
              if (snapshot.hasError) return const SizedBox(height: 32);
              if (shell == null) return const SizedBox(height: 32);
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final poem in shell.poems) ...[
                      ChoiceChip(
                        label: Text(poem.title),
                        avatar: (shell.unlocked[poem.poemId] ?? false)
                            ? null
                            : const Icon(Icons.lock_outline,
                                size: 16, color: AppColors.textFaint),
                        showCheckmark: false,
                        selected: poem.poemId == _selectedPoemId,
                        onSelected: (_) => _select(poem.poemId),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          FutureBuilder<_ListData>(
            future: _list,
            builder: (context, snapshot) {
              final list = snapshot.data;
              if (snapshot.hasError) {
                // C의 저장소는 저장하지 않은 시의 목록을 읽으면 예외를 던진다.
                return UnavailableNotice(onRetry: () => _select(_selectedPoemId));
              }
              if (list == null) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (!list.isUnlocked) {
                return LockedNotice(poemId: _selectedPoemId);
              }
              if (list.conversations.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: Text(
                      AppStrings.communityEmpty,
                      style: AppText.bodySub,
                    ),
                  ),
                );
              }
              return Column(
                children: [
                  for (final conversation in list.conversations)
                    _ConversationCard(
                      conversation: conversation,
                      authorNickname:
                          list.nicknames[conversation.userId] ?? '',
                      onTap: () => Navigator.of(context).pushNamed(
                        AppRoutes.communityDetail(conversation.conversationId),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ConversationCard extends StatelessWidget {
  const _ConversationCard({
    required this.conversation,
    required this.authorNickname,
    required this.onTap,
  });

  final PublicConversation conversation;
  final String authorNickname;
  final VoidCallback onTap;

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
                      authorNickname,
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
                      style: AppText.caption,
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
