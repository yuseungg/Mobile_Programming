// S05 대화 — 주인: A
// 상단 고정 시, 말풍선, 입력창, 힌트 · 정리하기 버튼.
// 근거 검증은 이 화면의 상태: 확인된 근거 행 = 초록 실선, 가리키는 중 = 회색 점선.
// 에이전트는 lib/agent/chat_agent.dart — 키가 있으면 OpenRouter, 없으면 가짜 에이전트가 답한다.
// ⚠ 대화와 근거 행은 아직 이 화면 안에만 있다. C의 저장소가 생기면 Reading에 쓴다 (S06이 거기서 읽는다).
import 'package:flutter/material.dart';

import '../../agent/cancel_token.dart';
import '../../agent/chat_agent.dart';
import '../../app/router.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../data/fakes/fake_data.dart';
import '../../data/models/chat_message.dart';
import '../../data/models/poem.dart';
import '../../data/models/reading.dart';
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
  final _scrollController = ScrollController();
  late final Poem _poem = FakeData.poemById(widget.poemId);
  late final Reading? _reading = FakeData.readingFor(widget.poemId);
  late final ChatAgent _agent = createChatAgent(
    settings: FakeData.settings,
    isSaved: _reading?.isSaved ?? false,
  );
  late final List<ChatMessage> _conversation = [...?_reading?.conversation];
  late final Set<int> _evidenceLines = {...?_reading?.evidenceLines};
  int? _pointingLine;
  CancelToken? _pendingReply; // 응답을 기다리는 동안만 있다

  bool get _isResponding => _pendingReply != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
      // 대화가 비어 있으면 첫 낱말에서 출발하는 첫 질문을 받는다
      if (_conversation.isEmpty) {
        _requestReply((cancelToken) => _agent.open(
              poem: _poem,
              firstWord: _reading?.firstWord ?? '',
              cancelToken: cancelToken,
            ));
      }
    });
  }

  @override
  void dispose() {
    _pendingReply?.cancel(); // 화면을 떠나면 남은 요청도 멈춘다
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _requestReply(
    Future<AgentReply> Function(CancelToken cancelToken) request,
  ) async {
    final cancelToken = CancelToken();
    setState(() => _pendingReply = cancelToken);
    _scrollToBottom();

    final reply = await request(cancelToken);
    if (!mounted || cancelToken.isCancelled) return;
    setState(() {
      _pendingReply = null;
      _conversation.add(ChatMessage(role: ChatRole.assistant, text: reply.text));
      _evidenceLines.addAll(reply.evidenceLines);
      _pointingLine = reply.pointingLine;
    });
    _scrollToBottom();
  }

  void _send() {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isResponding) return;
    _messageController.clear();
    setState(() => _conversation.add(ChatMessage(role: ChatRole.user, text: text)));

    final conversation = List<ChatMessage>.unmodifiable(_conversation);
    _requestReply((cancelToken) => _agent.reply(
          poem: _poem,
          conversation: conversation,
          cancelToken: cancelToken,
        ));
  }

  /// 대화 중단 (기획서 7장) — 응답을 기다리지 않고 바로 다시 입력할 수 있다
  void _stop() {
    _pendingReply?.cancel();
    setState(() => _pendingReply = null);
  }

  Future<void> _showHint() async {
    final cancelToken = CancelToken();
    final hint = _agent.hint(
      poem: _poem,
      conversation: List<ChatMessage>.unmodifiable(_conversation),
      cancelToken: cancelToken,
    );
    hint.then((reply) {
      if (!mounted || cancelToken.isCancelled) return;
      setState(() => _pointingLine = reply.pointingLine ?? _pointingLine);
    });

    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => _HintSheet(hint: hint),
    );
    cancelToken.cancel(); // 힌트가 오기 전에 닫았으면 요청을 멈춘다
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.chatTitle(_poem.title), style: AppText.bodySub),
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
                  poem: _poem,
                  compact: true,
                  showLineNumbers: true,
                  evidenceLines: _evidenceLines,
                  pointingLine: _pointingLine,
                ),
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                itemCount: _conversation.length + (_isResponding ? 1 : 0),
                itemBuilder: (context, index) => index < _conversation.length
                    ? ChatBubble(message: _conversation[index])
                    : const ChatBubble(
                        message: ChatMessage(
                          role: ChatRole.assistant,
                          text: AppStrings.chatResponding,
                        ),
                        isPending: true,
                      ),
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
                    isResponding: _isResponding,
                    onSend: _send,
                    onStop: _stop,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isResponding ? null : _showHint,
                          child: const Text(AppStrings.chatHintButton),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context)
                              .pushNamed(AppRoutes.save(_poem.poemId)),
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

/// 힌트 시트 — 관찰 질문이 올 때까지 진행 막대를 보여 준다
class _HintSheet extends StatelessWidget {
  const _HintSheet({required this.hint});

  final Future<AgentReply> hint;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(AppStrings.chatHintTitle, style: AppText.label),
            const SizedBox(height: 10),
            FutureBuilder<AgentReply>(
              future: hint,
              builder: (context, snapshot) {
                final reply = snapshot.data;
                if (reply == null) return const LinearProgressIndicator();
                return Text(reply.text, style: AppText.bodyStrong);
              },
            ),
          ],
        ),
      ),
    );
  }
}
