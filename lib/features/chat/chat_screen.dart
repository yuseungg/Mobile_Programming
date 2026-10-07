// S05 대화 — 주인: A
// 상단 고정 시, 말풍선, 입력창, 힌트 · 정리하기 버튼.
// 근거 검증은 이 화면의 상태: 확인된 근거 행 = 초록 실선, 가리키는 중 = 회색 점선.
// 1단계: 가짜 대화를 보여준다. 보내기는 아무 일도 하지 않는다. 에이전트는 2단계.
import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../data/fakes/fake_data.dart';
import '../../shared/widgets/chat_bubble.dart';
import '../../shared/widgets/message_input.dart';
import '../../shared/widgets/poem_view.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.poemId});

  final String poemId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _showHint() {
    final hint = FakeData.hints[widget.poemId];
    if (hint == null) return;
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(AppStrings.chatHintTitle, style: AppText.label),
              const SizedBox(height: 10),
              Text(hint, style: AppText.bodyStrong),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final poem = FakeData.poemById(widget.poemId);
    final reading = FakeData.readingFor(widget.poemId);
    final conversation = reading?.conversation ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.chatTitle(poem.title), style: AppText.bodySub),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 상단 고정 시 — 스크롤만 되고 입력 필드가 아니다
            Container(
              constraints: const BoxConstraints(maxHeight: 150),
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: SingleChildScrollView(
                child: PoemView(
                  poem: poem,
                  compact: true,
                  showLineNumbers: true,
                  evidenceLines: {...?reading?.evidenceLines},
                  pointingLine: FakeData.pointingLines[widget.poemId],
                ),
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                itemCount: conversation.length,
                itemBuilder: (context, index) =>
                    ChatBubble(message: conversation[index]),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: const BoxDecoration(
                color: AppColors.background,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                children: [
                  MessageInput(
                    controller: _messageController,
                    onSend: () {},
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _showHint,
                          child: const Text(AppStrings.chatHintButton),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context)
                              .pushNamed(AppRoutes.save(poem.poemId)),
                          child: const Text(AppStrings.chatSummarizeButton),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
