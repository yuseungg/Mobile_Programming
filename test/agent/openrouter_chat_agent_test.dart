// 진짜 에이전트의 루프 (A) — 기획서 6장 「에이전트 구조」
// 네트워크 대신 정해진 응답을 차례로 돌려주는 가짜 전송을 끼워서, 무료 한도를 쓰지 않고 확인한다.
import 'dart:async';
import 'dart:convert';
import 'dart:io' show HttpException;

import 'package:flutter_test/flutter_test.dart';
import 'package:yeobaek/agent/cancel_token.dart';
import 'package:yeobaek/agent/openrouter_chat_agent.dart';
import 'package:yeobaek/agent/openrouter_client.dart';
import 'package:yeobaek/agent/prompts/fallback_questions.dart';
import 'package:yeobaek/agent/transport/http_types.dart';
import 'package:yeobaek/data/fakes/fake_data.dart';
import 'package:yeobaek/data/models/chat_message.dart';
import 'package:yeobaek/data/models/settings.dart';
import 'package:yeobaek/data/repositories.dart';
import 'package:yeobaek/ports/repository_reading_source.dart';

/// 정해진 응답을 차례로 돌려주고, 보낸 요청 본문을 모아 둔다
class _ScriptedTransport {
  _ScriptedTransport(List<HttpResponseData> responses)
      : _responses = [...responses];

  final List<HttpResponseData> _responses;
  final requests = <Map<String, Object?>>[];

  Future<HttpResponseData> post(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
    required Duration timeout,
    CancelToken? cancelToken,
  }) async {
    requests.add(jsonDecode(body) as Map<String, Object?>);
    return _responses.removeAt(0);
  }
}

/// 답이 오지 않는 전송 — 끊길 때(cancelToken)까지 기다린다. 끊기면 요청이 깨진 것처럼 던진다
class _HangingTransport {
  bool wasAborted = false;

  Future<HttpResponseData> post(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
    required Duration timeout,
    CancelToken? cancelToken,
  }) {
    final aborted = Completer<HttpResponseData>();
    cancelToken?.addListener(() {
      wasAborted = true;
      aborted.completeError(const HttpException('aborted'));
    });
    return aborted.future;
  }
}

HttpResponseData _toolCall(String name, Map<String, Object?> arguments) =>
    HttpResponseData(
      statusCode: 200,
      body: jsonEncode({
        'choices': [
          {
            'finish_reason': 'tool_calls',
            'message': {
              'role': 'assistant',
              'content': null,
              'tool_calls': [
                {
                  'id': 'call_$name',
                  'type': 'function',
                  'function': {'name': name, 'arguments': jsonEncode(arguments)},
                },
              ],
            },
          },
        ],
      }),
    );

HttpResponseData _text(String text) => HttpResponseData(
      statusCode: 200,
      body: jsonEncode({
        'choices': [
          {
            'finish_reason': 'stop',
            'message': {'role': 'assistant', 'content': text},
          },
        ],
      }),
    );

HttpResponseData _error(int statusCode, String message) => HttpResponseData(
      statusCode: statusCode,
      body: jsonEncode({
        'error': {'code': statusCode, 'message': message},
      }),
    );

void main() {
  final seosi = FakeData.poemById('seosi');
  const quoteMessage = ChatMessage(
    role: ChatRole.user,
    text: "'별을 그리워하며'라는 구절 때문에 그렇게 느꼈어요.",
  );
  const goodQuestion =
      "그 표현은 이 시에 없어요. '별'이 나오는 건 5행과 10행인데, 둘 중 어느 쪽이었을까요?";

  OpenRouterChatAgent agentWith(_ScriptedTransport transport) =>
      OpenRouterChatAgent(
        client: OpenRouterClient(apiKey: 'test-key', postJson: transport.post),
        model: 'test/model',
        tone: Tone.plain,
        isSaved: false,
      );

  List<Map<String, Object?>> toolOutputs(Map<String, Object?> request) => [
        for (final message in request['messages'] as List)
          if ((message as Map)['role'] == 'tool')
            jsonDecode(message['content'] as String) as Map<String, Object?>,
      ];

  test('시연 시나리오: verify_quote 실패 → search_poem_lines 재탐색 → 행을 가리키며 되묻는다', () async {
    final transport = _ScriptedTransport([
      _toolCall('verify_quote', {'quote': '별을 그리워하며'}),
      _toolCall('search_poem_lines', {'word': '별'}),
      _text(goodQuestion),
    ]);
    final reply = await agentWith(transport)
        .reply(poem: seosi, conversation: const [quoteMessage]);

    expect(reply.text, goodQuestion);
    expect(reply.isFallback, isFalse);
    expect(reply.evidenceLines, isEmpty);
    expect(reply.pointingLine, 5);
    final outputs = toolOutputs(transport.requests.last);
    expect(outputs.first, {'found': false, 'quote': '별을 그리워하며'});
    expect(outputs.last['matches'], hasLength(2));
  });

  test('출력 필터에 걸리면 이유를 알려 주고 다시 쓰게 한다', () async {
    final transport = _ScriptedTransport([
      _text('이 시는 부끄러움을 뜻합니다.'),
      _text('어느 행에서 부끄러움이 느껴졌나요?'),
    ]);
    final reply = await agentWith(transport)
        .reply(poem: seosi, conversation: const [quoteMessage]);

    expect(reply.text, '어느 행에서 부끄러움이 느껴졌나요?');
    expect(reply.isFallback, isFalse);
    final rewriteRequest = transport.requests.last;
    expect(rewriteRequest['tool_choice'], 'none');
    expect(
      ((rewriteRequest['messages'] as List).last as Map)['content'],
      contains('규칙에 맞지 않았다'),
    );
  });

  test('두 번 다시 써도 걸리면 준비된 관찰 질문으로 대신한다', () async {
    final transport = _ScriptedTransport([
      for (var i = 0; i < 3; i++) _text('이 시는 부끄러움을 뜻합니다.'),
    ]);
    final reply = await agentWith(transport)
        .reply(poem: seosi, conversation: const [quoteMessage]);

    expect(reply.isFallback, isTrue);
    expect(reply.text, fallbackQuestions['seosi']!.first);
    expect(transport.requests, hasLength(3)); // 처음 1번 + 다시 쓰기 2번
  });

  test('모델 호출이 실패하면(429) 준비된 관찰 질문으로 대신한다', () async {
    final transport =
        _ScriptedTransport([_error(429, 'temporarily rate-limited upstream')]);
    final reply = await agentWith(transport)
        .reply(poem: seosi, conversation: const [quoteMessage]);

    expect(reply.isFallback, isTrue);
    expect(transport.requests, hasLength(1));
  });

  test('힌트를 청할 때 직전 질문을 함께 알려 주고, 실패하면 그 질문의 짝 힌트로 대신한다', () async {
    final lastQuestion = fallbackQuestions['seosi']![1]; // 별이 나오는 두 행
    final conversation = [ChatMessage(role: ChatRole.assistant, text: lastQuestion)];

    final okTransport = _ScriptedTransport([_text("5행에서 '별' 바로 뒤에는 어떤 말이 오나요?")]);
    await agentWith(okTransport).hint(poem: seosi, conversation: conversation);
    final instruction =
        ((okTransport.requests.single['messages'] as List).last as Map)['content'];
    expect(instruction, contains('힌트를 눌렀다'));
    expect(instruction, contains(lastQuestion));

    final failTransport =
        _ScriptedTransport([_error(429, 'temporarily rate-limited upstream')]);
    final reply =
        await agentWith(failTransport).hint(poem: seosi, conversation: conversation);
    expect(reply.isFallback, isTrue);
    expect(reply.text, preparedQuestions['seosi']![1].hint);
  });

  group('힌트는 빨라야 한다 — 실기기에서 30초~1분 걸렸다', () {
    const goodHint = "5행에서 '별' 바로 뒤에는 어떤 말이 오나요?";
    final conversation = [
      ChatMessage(role: ChatRole.assistant, text: fallbackQuestions['seosi']![1]),
    ];

    test('툴 없이, 속으로 생각하지 말라고 하고 한 번에 받는다', () async {
      final transport = _ScriptedTransport([_text(goodHint)]);
      final reply =
          await agentWith(transport).hint(poem: seosi, conversation: conversation);

      expect(reply.text, goodHint);
      expect(reply.isFallback, isFalse);
      final request = transport.requests.single; // 툴 라운드가 없다
      expect(request['tools'], isNull);
      expect(request['tool_choice'], isNull);
      expect(request['reasoning'], {'enabled': false});
    });

    test('추론을 끌 수 없는 모델이면 켠 채로 다시 부르고, 다음부터는 청하지 않는다', () async {
      final transport = _ScriptedTransport([
        _error(400, 'Reasoning is mandatory for this endpoint and cannot be disabled.'),
        _text(goodHint),
        _text(goodHint),
      ]);
      final agent = agentWith(transport);

      final first = await agent.hint(poem: seosi, conversation: conversation);
      expect(first.text, goodHint);
      expect(first.isFallback, isFalse);
      expect(transport.requests[0]['reasoning'], {'enabled': false});
      expect(transport.requests[1].containsKey('reasoning'), isFalse);

      await agent.hint(poem: seosi, conversation: conversation);
      expect(transport.requests, hasLength(3));
      expect(transport.requests[2].containsKey('reasoning'), isFalse);
    });

    test('시간 안에 안 오면 요청을 끊고 직전 질문의 짝 힌트를 보여 준다', () async {
      final transport = _HangingTransport();
      final agent = OpenRouterChatAgent(
        client: OpenRouterClient(apiKey: 'test-key', postJson: transport.post),
        model: 'test/model',
        tone: Tone.plain,
        isSaved: false,
        hintDeadline: const Duration(milliseconds: 50),
      );

      final reply = await agent.hint(poem: seosi, conversation: conversation);
      expect(reply.isFallback, isTrue);
      expect(reply.text, preparedQuestions['seosi']![1].hint);
      expect(transport.wasAborted, isTrue); // 기다리던 요청은 끊었다
    });

    test('질문도 속으로 생각하지 말라고 하고 보낸다 — 툴은 그대로 쓴다', () async {
      final transport = _ScriptedTransport([_text(goodQuestion)]);
      await agentWith(transport)
          .reply(poem: seosi, conversation: const [quoteMessage]);

      final request = transport.requests.single;
      expect(request['tools'], isNotNull);
      expect(request['reasoning'], {'enabled': false});
    });
  });

  test('HTTP 200이어도 본문에 error가 있으면 실패로 본다', () async {
    final transport = _ScriptedTransport([
      HttpResponseData(
        statusCode: 200,
        body: jsonEncode({
          'error': {'code': 502, 'message': 'Upstream error from Nvidia'},
        }),
      ),
    ]);
    final reply = await agentWith(transport)
        .reply(poem: seosi, conversation: const [quoteMessage]);

    expect(reply.isFallback, isTrue);
  });

  test('툴 라운드는 5회까지 — 마지막 라운드는 툴 없이 답하게 한다', () async {
    final transport = _ScriptedTransport([
      for (var i = 0; i < 4; i++) _toolCall('search_poem_lines', {'word': '별'}),
      _text(goodQuestion),
    ]);
    final reply = await agentWith(transport)
        .reply(poem: seosi, conversation: const [quoteMessage]);

    expect(reply.isFallback, isFalse);
    expect(transport.requests, hasLength(5));
    expect(transport.requests.first.containsKey('tool_choice'), isFalse);
    expect(transport.requests.last['tool_choice'], 'none');
  });

  test('저장 전에는 D의 툴(get_poem_context)을 거부한다', () async {
    final transport = _ScriptedTransport([
      _toolCall('get_poem_context', const {}),
      _text(goodQuestion),
    ]);
    await agentWith(transport)
        .reply(poem: seosi, conversation: const [quoteMessage]);

    expect(
      toolOutputs(transport.requests.last).single['error'],
      contains('저장한 뒤에만'),
    );
  });

  test('취소하면 요청을 보내지 않는다', () async {
    final transport = _ScriptedTransport(const []);
    final cancelToken = CancelToken()..cancel();
    final reply = await agentWith(transport).reply(
      poem: seosi,
      conversation: const [quoteMessage],
      cancelToken: cancelToken,
    );

    expect(transport.requests, isEmpty);
    expect(reply.isFallback, isTrue);
  });

  test('모델을 부를 때마다 사용량을 센다 — 툴 라운드 · 다시 쓰기 포함', () async {
    final transport = _ScriptedTransport([
      _toolCall('verify_quote', {'quote': '별을 그리워하며'}),
      _text('이 시는 부끄러움을 뜻합니다.'), // 출력 필터에 걸려 다시 쓴다
      _text(goodQuestion),
    ]);
    var callCount = 0;
    final agent = OpenRouterChatAgent(
      client: OpenRouterClient(apiKey: 'test-key', postJson: transport.post),
      model: 'test/model',
      tone: Tone.plain,
      isSaved: false,
      onModelCall: () async => callCount++,
    );
    await agent.reply(poem: seosi, conversation: const [quoteMessage]);

    expect(transport.requests, hasLength(3));
    expect(callCount, 3);
  });

  List<String> toolNamesOf(Map<String, Object?> request) => [
        for (final tool in request['tools'] as List)
          ((tool as Map)['function'] as Map)['name'] as String,
      ];
  String systemPromptOf(Map<String, Object?> request) =>
      ((request['messages'] as List).first as Map)['content'] as String;

  test('저장 전에는 D의 툴을 보내지 않고, 저장 뒤 규칙도 붙이지 않는다', () async {
    final transport = _ScriptedTransport([_text(goodQuestion)]);
    await agentWith(transport)
        .reply(poem: seosi, conversation: const [quoteMessage]);

    final request = transport.requests.single;
    expect(toolNamesOf(request), ['verify_quote', 'search_poem_lines']);
    expect(systemPromptOf(request), isNot(contains('해석을 저장한 뒤')));
  });

  test('저장 뒤에는 compare_with_experts를 불러 관계를 받고 질문으로 잇는다', () async {
    const compareQuestion =
        '10행을 근거로 든 점이 전문가 해석 B와 같아요. 그 행에서 무엇이 가장 먼저 보였나요?';
    final transport = _ScriptedTransport([
      _toolCall('compare_with_experts', const {}),
      _text(compareQuestion),
    ]);
    var loadCount = 0;
    final agent = OpenRouterChatAgent(
      client: OpenRouterClient(apiKey: 'test-key', postJson: transport.post),
      model: 'test/model',
      tone: Tone.plain,
      isSaved: true,
      myEvidenceLines: const [10],
      myInterpretation: '밤은 그대로 온다',
      loadExperts: () async {
        loadCount++;
        return FakeData.expertInterpretations['seosi']!;
      },
    );
    const askMessage =
        ChatMessage(role: ChatRole.user, text: '전문가들은 어떻게 읽었어요?');
    final reply =
        await agent.reply(poem: seosi, conversation: const [askMessage]);

    expect(reply.text, compareQuestion);
    expect(reply.isFallback, isFalse);
    expect(loadCount, 1);
    final first = transport.requests.first;
    expect(toolNamesOf(first), [
      'verify_quote',
      'search_poem_lines',
      'compare_with_experts',
      'get_poem_context',
    ]);
    expect(systemPromptOf(first), contains('해석을 저장한 뒤'));
    final output = toolOutputs(transport.requests.last).single;
    final relations = [
      for (final expert in output['experts'] as List)
        (expert as Map)['relation'],
    ];
    expect(relations, ['differentLines', 'sameLines']);
  });

  test('저장 뒤라도 compare_with_experts를 부르지 않으면 전문가 해석을 읽지 않고 잠그지도 않는다',
      () async {
    final transport = _ScriptedTransport([_text(goodQuestion)]);
    var loadCount = 0;
    var openedCount = 0;
    final agent = OpenRouterChatAgent(
      client: OpenRouterClient(apiKey: 'test-key', postJson: transport.post),
      model: 'test/model',
      tone: Tone.plain,
      isSaved: true,
      loadExperts: () async {
        loadCount++;
        return const [];
      },
      onComparisonOpened: () async => openedCount++,
    );
    await agent.reply(poem: seosi, conversation: const [quoteMessage]);

    expect(loadCount, 0);
    expect(openedCount, 0);
  });

  // 기획서 4장 — 잠금의 기준은 「전문가 해석을 봤는가」. S05에서 봐도 S07을 연 것과 같다
  group('S05에서 전문가 해석을 보면 해석이 잠긴다', () {
    setUp(() => Repositories.useFakes());

    test('두 번 불러도 잠금은 한 번만 건다', () async {
      final transport = _ScriptedTransport([
        _toolCall('compare_with_experts', const {}),
        _toolCall('compare_with_experts', const {}),
        _text(goodQuestion),
      ]);
      var openedCount = 0;
      final agent = OpenRouterChatAgent(
        client: OpenRouterClient(apiKey: 'test-key', postJson: transport.post),
        model: 'test/model',
        tone: Tone.plain,
        isSaved: true,
        loadExperts: () async => FakeData.expertInterpretations['seosi']!,
        onComparisonOpened: () async => openedCount++,
      );
      await agent.reply(poem: seosi, conversation: const [quoteMessage]);

      expect(openedCount, 1);
    });

    test('잠금이 저장소까지 가서, 그 뒤로 해석을 고치면 막힌다', () async {
      final userId = FakeData.myUserId;
      final before = await Repositories.reading.fetchReading(userId, 'seosi');
      expect(before!.isSaved, isTrue);
      expect(before.hasOpenedComparison, isFalse);

      final transport = _ScriptedTransport([
        _toolCall('compare_with_experts', const {}),
        _text(goodQuestion),
      ]);
      final agent = OpenRouterChatAgent(
        client: OpenRouterClient(apiKey: 'test-key', postJson: transport.post),
        model: 'test/model',
        tone: Tone.plain,
        isSaved: true,
        myEvidenceLines: before.evidenceLines,
        myInterpretation: before.interpretation,
        loadExperts: () async => FakeData.expertInterpretations['seosi']!,
        onComparisonOpened: () =>
            const RepositoryReadingSource().markComparisonOpened('seosi'),
      );
      await agent.reply(poem: seosi, conversation: const [quoteMessage]);

      final after = await Repositories.reading.fetchReading(userId, 'seosi');
      expect(after!.hasOpenedComparison, isTrue);
      await expectLater(
        Repositories.reading.saveInterpretation(
          userId,
          after.copyWith(interpretation: '${after.interpretation} 고쳐 씀'),
          summary: null,
        ),
        throwsA(isA<InterpretationLockedException>()),
      );
    });
  });

  test('사용량을 못 세도 답은 온다', () async {
    final transport = _ScriptedTransport([_text(goodQuestion)]);
    final agent = OpenRouterChatAgent(
      client: OpenRouterClient(apiKey: 'test-key', postJson: transport.post),
      model: 'test/model',
      tone: Tone.plain,
      isSaved: false,
      onModelCall: () async => throw StateError('저장 실패'),
    );
    final reply =
        await agent.reply(poem: seosi, conversation: const [quoteMessage]);

    expect(reply.text, goodQuestion);
    expect(reply.isFallback, isFalse);
  });
}
