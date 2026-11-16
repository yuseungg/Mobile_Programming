// 진짜 에이전트의 루프 (A) — 기획서 6장 「에이전트 구조」
// 네트워크 대신 정해진 응답을 차례로 돌려주는 가짜 전송을 끼워서, 무료 한도를 쓰지 않고 확인한다.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:yeobaek/agent/cancel_token.dart';
import 'package:yeobaek/agent/openrouter_chat_agent.dart';
import 'package:yeobaek/agent/openrouter_client.dart';
import 'package:yeobaek/agent/prompts/fallback_questions.dart';
import 'package:yeobaek/agent/transport/http_types.dart';
import 'package:yeobaek/data/fakes/fake_data.dart';
import 'package:yeobaek/data/models/chat_message.dart';
import 'package:yeobaek/data/models/settings.dart';

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
