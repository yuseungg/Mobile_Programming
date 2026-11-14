// 주인: A — 진짜 에이전트 (기획서 6장 「에이전트 구조」)
// 고정된 순서로 흐르지 않는다. 모델이 사용자의 말을 읽고 어떤 툴을 어떤 인자로 부를지 스스로 정하고,
// 툴 결과를 다시 읽고 다음 행동을 정한다.
// - 라운드 상한: 한 턴당 툴 라운드 5회. 마지막 라운드는 툴 없이 답하게 한다
// - 출력 필터에 걸리면 이유를 알려 주고 다시 쓰게 한다. 2회까지. 그래도 안 되면 준비된 관찰 질문
// - 모델 호출이 실패해도 준비된 관찰 질문으로 대신한다 (기획서 7장)
// S05는 질문 모델 하나로 툴 호출과 질문을 함께 한다. 비교 모델은 D가 S07 · S09에서 쓴다.
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../data/models/chat_message.dart';
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
    this.onModelCall,
  });

  static const maxToolRounds = 5;
  static const maxRewrites = 2;

  final OpenRouterClient client;
  final String model; // 질문 모델 — 설정(S10 · S11)의 questionModel
  final Tone tone;
  final bool isSaved; // 그 시의 해석을 저장했는가 — 툴 권한이 달라진다

  /// 모델을 한 번 부를 때마다 (툴 라운드 · 다시 쓰기 포함). 설정 화면의 이번 달 사용량.
  final Future<void> Function()? onModelCall;

  Future<ChatCompletion> _complete({
    required List<Map<String, Object?>> messages,
    required List<Map<String, Object?>> tools,
    String? toolChoice,
    CancelToken? cancelToken,
  }) {
    _countModelCall();
    return client.complete(
      model: model,
      messages: messages,
      tools: tools,
      toolChoice: toolChoice,
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

  @override
  Future<AgentReply> hint({
    required Poem poem,
    required List<ChatMessage> conversation,
    CancelToken? cancelToken,
  }) {
    return _respond(
      poem: poem,
      conversation: conversation,
      instruction: hintInstruction,
      fallbackText: nextFallbackQuestion(poem.poemId, conversation),
      cancelToken: cancelToken,
    );
  }

  Future<AgentReply> _respond({
    required Poem poem,
    required List<ChatMessage> conversation,
    String? instruction, // 화면에 보이지 않는 앱 안내 (첫 질문 · 힌트)
    required String fallbackText,
    CancelToken? cancelToken,
  }) async {
    final tools = AgentTools(poem: poem, isSaved: isSaved);
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
      {'role': 'system', 'content': buildSystemPrompt(poem, tone)},
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
          tools: tools.definitions,
          toolChoice: isLastRound ? 'none' : null,
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
        for (final call in completion.toolCalls) {
          final result = tools.run(call.name, call.arguments);
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
          tools: tools.definitions,
          toolChoice: 'none',
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
