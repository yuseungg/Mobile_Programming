// 주인: A — 진짜 에이전트 (기획서 6장 「에이전트 구조」)
// 고정된 순서로 흐르지 않는다. 모델이 사용자의 말을 읽고 어떤 툴을 어떤 인자로 부를지 스스로 정하고,
// 툴 결과를 다시 읽고 다음 행동을 정한다.
// - 라운드 상한: 한 턴당 툴 라운드 5회. 마지막 라운드는 툴 없이 답하게 한다
// - 출력 필터에 걸리면 이유를 알려 주고 다시 쓰게 한다. 2회까지. 그래도 안 되면 준비된 관찰 질문
// - 모델 호출이 실패해도 준비된 관찰 질문으로 대신한다 (기획서 7장)
// S05는 질문 모델 하나로 툴 호출과 질문을 함께 한다. 비교 모델은 D가 S07 · S09에서 쓴다.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../data/models/chat_message.dart';
import '../data/models/expert_interpretation.dart';
import '../data/models/poem.dart';
import '../data/models/settings.dart';
import 'cancel_token.dart';
import 'chat_agent.dart';
import 'line_marks.dart';
import 'openrouter_client.dart';
import 'output_guard.dart';
import 'prompts/fallback_questions.dart';
import 'prompts/system_prompt.dart';
import 'tools/agent_tools.dart';
import 'tools/search_poem_lines.dart';
import 'tools/verify_quote.dart';

class OpenRouterChatAgent implements ChatAgent {
  OpenRouterChatAgent({
    required this.client,
    required this.model,
    required this.tone,
    required this.isSaved,
    this.myEvidenceLines = const [],
    this.myInterpretation = '',
    this.loadExperts,
    this.onComparisonOpened,
    this.onModelCall,
    this.hintDeadline = defaultHintDeadline,
  });

  static const maxToolRounds = 5;
  static const maxRewrites = 2;

  /// 힌트는 이 안에 오지 않으면 직전 질문의 짝 힌트(fallback_questions.dart)로 대신한다.
  /// 힌트를 누른 사람은 막혀 있는 사람이다 — 실기기에서 30초~1분 기다리면 멈춘 것으로 보였다.
  static const defaultHintDeadline = Duration(seconds: 15);
  final Duration hintDeadline;

  /// 추론을 끌 수 없는 모델이 있다 (끄라고 하면 400). 한 번 겪으면 다시 청하지 않는다.
  bool _reasoningAlwaysOn = false;

  final OpenRouterClient client;
  final String model; // 질문 모델 — 설정(S10 · S11)의 questionModel
  final Tone tone;
  final bool isSaved; // 그 시의 해석을 저장했는가 — 툴 권한이 달라진다

  // 저장 뒤에만 쓰는 것 — compare_with_experts의 재료
  final List<int> myEvidenceLines; // 저장한 해석의 근거 행 (1부터)
  final String myInterpretation; // 저장한 해석

  /// 그 시의 전문가 해석을 읽는다. 모델이 compare_with_experts를 처음 부를 때 한 번만 부른다 —
  /// 에셋 읽기를 대화 시작에 묶지 않기 위해서다.
  final Future<List<ExpertInterpretation>> Function()? loadExperts;
  Future<List<ExpertInterpretation>>? _experts;

  /// 전문가 해석을 사용자에게 처음 보였을 때 한 번 (기획서 4장 잠금).
  /// 잠금의 기준은 「S07을 열었는가」가 아니라 「전문가 해석을 봤는가」다 —
  /// S05에서 compare_with_experts로 봐도 그 뒤로는 해석을 고칠 수 없다.
  final Future<void> Function()? onComparisonOpened;
  bool _isComparisonOpened = false;

  /// 모델을 한 번 부를 때마다 (툴 라운드 · 다시 쓰기 포함). 설정 화면의 이번 달 사용량.
  final Future<void> Function()? onModelCall;

  /// 못 읽으면 빈 목록 — 모델에게는 experts가 빈 채로 간다. 대화는 이어 간다
  Future<List<ExpertInterpretation>> _loadExperts() {
    final load = loadExperts;
    if (load == null) return Future.value(const []);
    return _experts ??= load().catchError((Object error) {
      debugPrint('[agent] 전문가 해석을 불러오지 못함: $error');
      return const <ExpertInterpretation>[];
    });
  }

  /// 잠금을 못 걸어도 대화는 이어 간다 (S07과 같은 규칙 — markComparisonOpened도 예외를 먹는다)
  Future<void> _markComparisonOpened() async {
    final mark = onComparisonOpened;
    if (mark == null || _isComparisonOpened) return;
    _isComparisonOpened = true;
    try {
      await mark();
    } catch (error) {
      debugPrint('[agent] 대조 열람을 기록하지 못함: $error');
    }
  }

  /// 모델을 한 번 부른다. [reasoningOff]면 속으로 생각하지 말라고 청한다 — 무료 모델은
  /// 답하기 전에 수천 토큰을 생각하느라 한 번에 15~60초가 걸렸다 (실측).
  /// 끌 수 없는 모델이면 켠 채로 한 번 더 부른다.
  Future<ChatCompletion> _complete({
    required List<Map<String, Object?>> messages,
    List<Map<String, Object?>>? tools,
    String? toolChoice,
    bool reasoningOff = false,
    Duration? timeout,
    CancelToken? cancelToken,
  }) async {
    final asksReasoningOff = reasoningOff && !_reasoningAlwaysOn;
    _countModelCall();
    final completion = await client.complete(
      model: model,
      messages: messages,
      tools: tools,
      toolChoice: toolChoice,
      reasoning: asksReasoningOff ? const {'enabled': false} : null,
      timeout: timeout,
      cancelToken: cancelToken,
    );
    final failure = completion.failure;
    final isReasoningRefused = asksReasoningOff &&
        failure != null &&
        failure.statusCode == 400 &&
        failure.message.toLowerCase().contains('reasoning');
    if (!isReasoningRefused) return completion;
    _reasoningAlwaysOn = true;
    debugPrint('[agent] 이 모델은 추론을 끌 수 없어 켠 채로 다시 부름: $failure');
    return _complete(
      messages: messages,
      tools: tools,
      toolChoice: toolChoice,
      timeout: timeout,
      cancelToken: cancelToken,
    );
  }

  /// 횟수를 못 세도 대화는 이어 간다
  void _countModelCall() {
    final count = onModelCall;
    if (count == null) return;
    count().catchError((Object error) {
      debugPrint('[agent] 호출 횟수를 세지 못함: $error');
    });
  }

  @override
  Future<AgentReply> open({
    required Poem poem,
    required String firstWord,
    CancelToken? cancelToken,
  }) {
    return _respond(
      poem: poem,
      conversation: const [],
      instruction: openingInstruction(firstWord),
      fallbackText: openingFallbackQuestion(firstWord),
      cancelToken: cancelToken,
    );
  }

  @override
  Future<AgentReply> reply({
    required Poem poem,
    required List<ChatMessage> conversation,
    CancelToken? cancelToken,
  }) {
    return _respond(
      poem: poem,
      conversation: conversation,
      fallbackText: nextFallbackQuestion(poem.poemId, conversation),
      cancelToken: cancelToken,
    );
  }

  /// 힌트는 빨라야 한다. 그래서 세 가지가 질문과 다르다.
  ///  - 툴 없이 한 번에 답하게 한다 — 툴 라운드만큼 호출이 늘어난다
  ///  - 속으로 생각하지 않게 한다 (끌 수 없는 모델은 켠 채로)
  ///  - [hintDeadline] 안에 안 오면 요청을 끊고 직전 질문의 짝 힌트를 보여 준다
  @override
  Future<AgentReply> hint({
    required Poem poem,
    required List<ChatMessage> conversation,
    CancelToken? cancelToken,
  }) async {
    // 화면이 시트를 닫아도, 시간이 다 돼도 같은 토큰으로 요청을 끊는다
    final hintToken = CancelToken();
    void cancelFromScreen() => hintToken.cancel();
    cancelToken?.addListener(cancelFromScreen);
    final deadline = Timer(hintDeadline, hintToken.cancel);
    try {
      final reply = await _respond(
        poem: poem,
        conversation: conversation,
        instruction: hintInstruction(lastAgentQuestion(conversation)),
        fallbackText: fallbackHint(poem.poemId, conversation),
        isHint: true,
        cancelToken: hintToken,
      );
      if (hintToken.isCancelled && !(cancelToken?.isCancelled ?? false)) {
        debugPrint('[agent] 힌트가 ${hintDeadline.inSeconds}초 안에 오지 않아 짝 힌트로 대신함');
      }
      return reply;
    } finally {
      deadline.cancel();
      cancelToken?.removeListener(cancelFromScreen);
    }
  }

  Future<AgentReply> _respond({
    required Poem poem,
    required List<ChatMessage> conversation,
    String? instruction, // 화면에 보이지 않는 앱 안내 (첫 질문 · 힌트)
    required String fallbackText,
    bool isHint = false, // 툴 없이 · 추론 없이 · 짧게 (hint 참고)
    CancelToken? cancelToken,
  }) async {
    var tools = AgentTools(
      poem: poem,
      isSaved: isSaved,
      myEvidenceLines: myEvidenceLines,
      myInterpretation: myInterpretation,
    );
    final userText =
        instruction == null && conversation.isNotEmpty && conversation.last.isUser
            ? conversation.last.text
            : '';
    final quoteChecks = <QuoteCheck>[];
    final searches = <List<LineMatch>>[];

    AgentReply finish(String text, {bool isFallback = false}) {
      final marks = resolveLineMarks(
        poem: poem,
        userText: userText,
        quoteChecks: quoteChecks,
        searches: searches,
        replyText: text,
      );
      return AgentReply(
        text: text,
        evidenceLines: marks.evidenceLines,
        pointingLine: marks.pointingLine,
        isFallback: isFallback,
      );
    }

    AgentReply fallback(Object reason) {
      if (!(cancelToken?.isCancelled ?? false)) {
        debugPrint('[agent] 준비된 관찰 질문으로 대신함: $reason');
      }
      return finish(fallbackText, isFallback: true);
    }

    final messages = <Map<String, Object?>>[
      {'role': 'system', 'content': buildSystemPrompt(poem, tone, isSaved: isSaved)},
      for (final message in conversation)
        {'role': message.isUser ? 'user' : 'assistant', 'content': message.text},
      if (instruction != null) {'role': 'user', 'content': instruction},
    ];

    try {
      // 1) 툴 라운드 — 모델이 툴을 고르고, 결과를 보고 다음 행동을 정한다
      var answer = '';
      for (var round = 1; round <= maxToolRounds; round++) {
        final isLastRound = round == maxToolRounds;
        final completion = await _complete(
          messages: messages,
          tools: isHint ? null : tools.definitions,
          toolChoice: isHint || !isLastRound ? null : 'none',
          reasoningOff: isHint,
          timeout: isHint ? hintDeadline : null,
          cancelToken: cancelToken,
        );
        final failure = completion.failure;
        if (failure != null) return fallback(failure);

        final assistantMessage = completion.assistantMessage;
        if (completion.toolCalls.isEmpty || isLastRound || assistantMessage == null) {
          answer = completion.content ?? '';
          break;
        }
        messages.add(assistantMessage);
        // compare_with_experts를 처음 부를 때 전문가 해석을 읽어 툴에 채운다
        final needsExperts = isSaved &&
            completion.toolCalls
                .any((call) => call.name == AgentTools.compareWithExpertsName);
        if (needsExperts && tools.experts.isEmpty) {
          tools = AgentTools(
            poem: poem,
            isSaved: isSaved,
            myEvidenceLines: myEvidenceLines,
            myInterpretation: myInterpretation,
            experts: await _loadExperts(),
          );
        }
        for (final call in completion.toolCalls) {
          final result = tools.run(call.name, call.arguments);
          // 전문가 해석이 모델에게 넘어갔으면 사용자도 본 것으로 친다 — 해석 잠금
          if (isSaved &&
              call.name == AgentTools.compareWithExpertsName &&
              tools.experts.isNotEmpty) {
            await _markComparisonOpened();
          }
          final quoteCheck = result.quoteCheck;
          final matches = result.matches;
          if (quoteCheck != null) quoteChecks.add(quoteCheck);
          if (matches != null) searches.add(matches);
          messages.add({
            'role': 'tool',
            'tool_call_id': call.id,
            'content': jsonEncode(result.output),
          });
        }
      }

      // 2) 출력 필터 — 걸리면 이유를 알려 주고 다시 쓰게 한다
      answer = OutputGuard.clean(answer);
      var check = OutputGuard.check(answer);
      for (var rewrite = 1; rewrite <= maxRewrites && !check.isPassed; rewrite++) {
        messages.addAll([
          if (answer.isNotEmpty) {'role': 'assistant', 'content': answer},
          {'role': 'user', 'content': rewriteInstruction(check.violations)},
        ]);
        final completion = await _complete(
          messages: messages,
          tools: isHint ? null : tools.definitions,
          toolChoice: isHint ? null : 'none',
          reasoningOff: isHint,
          timeout: isHint ? hintDeadline : null,
          cancelToken: cancelToken,
        );
        final failure = completion.failure;
        if (failure != null) return fallback(failure);
        answer = OutputGuard.clean(completion.content ?? '');
        check = OutputGuard.check(answer);
      }
      if (!check.isPassed) {
        final names = check.violations.map((violation) => violation.name).join(', ');
        return fallback('출력 필터 — $names');
      }
      return finish(answer);
    } catch (error) {
      return fallback(error);
    }
  }
}
