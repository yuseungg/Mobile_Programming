// S08 대화 목록 — 주인: D
// D의 part-d `S08DialogueListScreen`을 이름만 맞춰 옮겼다 (docs/여백-이름대조표.md).
// - 이 시를 읽은 사람들이 공개한 대화 목록 (최신순, 공감 수로 정렬하지 않음)
// - 카드 탭 → S09
// - 하단 탭 화면이라 시는 위의 칩으로 고른다 (해석을 저장하지 않은 시는 자물쇠)
// - 저장하지 않은 시를 고르면 목록 대신 잠금 안내를 보여 준다 (기획서 5장)
// - S09에서 공감하고 돌아오면 그 카드의 공감 수를 다시 읽는다
import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../data/models/poem.dart';
import '../../data/models/public_conversation.dart';
import '../../ports/repository_reading_source.dart';
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
    this.openCount = 0,
    this.source = const RepositoryReadingSource(),
  });

  /// 이 탭을 누른 횟수. 바뀌면 자물쇠를 다시 읽는다.
  ///
  /// 탭 화면은 IndexedStack 안에서 앱이 켜질 때 한 번 만들어지고 계속 살아
  /// 있다. 그래서 S06에서 해석을 저장하고 이 탭으로 와도 칩의 자물쇠가 그대로
  /// 잠겨 있었다 (태블릿 점검에서 나왔다. 앱을 껐다 켜야 풀렸다).
  ///
  /// 키를 새로 줘서 화면을 통째로 다시 만드는 길도 있고 S10이 그렇게 한다
  /// (`tab_shell.dart`의 `_settingsOpenCount`). 여기서는 숫자만 받는다 —
  /// 다시 만들면 목록과 스크롤 위치까지 날아가고 스피너가 한 번 번쩍인다.
  final int openCount;

  final ReadingSource source;

  @override
  State<CommunityListScreen> createState() => _CommunityListScreenState();
}

class _CommunityListScreenState extends State<CommunityListScreen> {
  late final ReadingSource _source = widget.source;
  late String _selectedPoemId = _source.todayPoemId;
  late Future<_ShellData> _shell = _loadShell();
  late Future<_ListData> _list = _loadList(_selectedPoemId);

  @override
  void didUpdateWidget(covariant CommunityListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.openCount != oldWidget.openCount) _refreshLocks();
  }

  /// 탭을 다시 눌렀을 때 자물쇠만 다시 읽는다.
  ///
  /// 읽기가 실패하면 **아무것도 하지 않는다.** 자물쇠가 잠시 낡은 것이
  /// 칩 줄이 사라지는 것보다 낫다 ([_refreshCard]와 같은 규칙이다).
  Future<void> _refreshLocks() async {
    final _ShellData shell;
    try {
      shell = await _loadShell();
    } catch (_) {
      return;
    }
    if (!mounted) return;

    // 보고 있던 시가 그사이 열렸으면 잠금 안내 대신 목록을 보여 줘야 한다.
    // 반대로 닫히는 일은 없다 (저장은 되돌릴 수 없다). 그래도 둘을 비교해
    // 바뀌었을 때만 다시 읽는다 — 목록을 괜히 새로 불러오지 않는다.
    final wasUnlocked = (await _list.catchError((_) => _lockedData)).isUnlocked;
    final isUnlocked = shell.unlocked[_selectedPoemId] ?? false;
    if (!mounted) return;

    setState(() {
      // SynchronousFuture라 칩 줄이 한 프레임도 비지 않는다.
      _shell = SynchronousFuture(shell);
      if (isUnlocked != wasUnlocked) _list = _loadList(_selectedPoemId);
    });
  }

  static const _lockedData = _ListData(
    isUnlocked: false,
    conversations: [],
    nicknames: {},
  );

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
    if (!await _isUnlocked(poemId)) return _lockedData;
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

  /// S09에서 돌아왔을 때 그 카드 하나만 다시 읽는다.
  ///
  /// 목록은 시를 고를 때 한 번만 불러온다. 그래서 상세에서 공감을 눌러도
  /// 돌아온 목록의 공감 수는 그대로였다 (C의 지적, S08).
  ///
  /// 목록 전체를 다시 불러오지 않는 이유는 둘이다. 카드가 사라지고 스피너가
  /// 떴다가 돌아오는 깜빡임이 생기고, 닉네임을 사람 수만큼 다시 읽는다.
  /// 바뀔 수 있는 것은 방금 들어갔던 그 대화뿐이다.
  ///
  /// 다시 읽기가 실패하면 **아무것도 하지 않는다.** 공감 수가 잠시 낡은 것은
  /// 목록이 사라지는 것보다 낫다.
  Future<void> _refreshCard(_ListData current, String conversationId) async {
    final PublicConversation updated;
    try {
      updated = await _source.conversationById(conversationId);
    } catch (_) {
      return;
    }
    if (!mounted) return;
    setState(() {
      // SynchronousFuture라 FutureBuilder가 한 프레임도 비우지 않는다.
      _list = SynchronousFuture(
        _ListData(
          isUnlocked: current.isUnlocked,
          conversations: [
            for (final c in current.conversations)
              c.conversationId == conversationId ? updated : c,
          ],
          nicknames: current.nicknames,
        ),
      );
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
                      onTap: () async {
                        await Navigator.of(context).pushNamed(
                          AppRoutes.communityDetail(
                              conversation.conversationId),
                        );
                        await _refreshCard(
                            list, conversation.conversationId);
                      },
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
                      style: AppText.cardTitle,
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
                        style: AppText.firstWordTag,
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
                  style: AppText.caption.copyWith(fontSize: 13, color: AppColors.textSub),
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
                    style: AppText.interpretationPreview,
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
