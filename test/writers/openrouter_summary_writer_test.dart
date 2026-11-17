// 주인: D — 대화 요약을 모델에게 쓰게 하는 쪽 (기획서 F7 「AI 요약」)
// 네트워크 대신 정해진 응답을 돌려주는 가짜 전송을 끼운다 — 무료 한도를 쓰지 않는다.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:yeobaek/agent/cancel_token.dart';
import 'package:yeobaek/agent/openrouter_client.dart';
import 'package:yeobaek/agent/transport/http_types.dart';
import 'package:yeobaek/app/strings.dart';
import 'package:yeobaek/data/models/chat_message.dart';
import 'package:yeobaek/data/models/settings.dart';
import 'package:yeobaek/writers/fake_summary_writer.dart';
import 'package:yeobaek/writers/openrouter_summary_writer.dart';
import 'package:yeobaek/writers/summary_writer.dart';

import '../support/stub_reading_source.dart';

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
  const conversation = [
    ChatMessage(
      role: ChatRole.assistant,
      text: "'별'이 나오는 행은 5행과 10행인데, 어느 쪽이 먼저 눈에 들어왔나요?",
    ),
    ChatMessage(role: ChatRole.user, text: '10행이요. 바람에 스치운다는 말이 오래 남았어요.'),
  ];

  const request = SummaryRequest(
    poemId: 'seosi',
    firstWord: '별',
    conversation: conversation,
    interpretation: '별은 멀리 있어서 오래 보게 되는 것 같다.',
  );

  // 요약을 못 썼을 때 들어가는 사실 문장 (첫 낱말 + AI 질문 수)
  final fallbackText = AppStrings.communitySummaryFallback('별', 1);

  var callCount = 0;
  OpenRouterSummaryWriter writerWith(_ScriptedTransport transport) {
    callCount = 0;
    return OpenRouterSummaryWriter(
      client: OpenRouterClient(apiKey: 'test-key', postJson: transport.post),
      model: 'test/model',
      fallback: const FakeSummaryWriter(),
      source: StubReadingSource(),
      tone: Tone.plain,
      onModelCall: () async => callCount++,
    );
  }

  String userOf(Map<String, Object?> request) => [
        for (final message in request['messages'] as List)
          if ((message as Map)['role'] == 'user') '${message['content']}',
      ].join('\n');

  test('모델이 쓴 요약을 그대로 쓴다 — 폴백이 아니다', () async {
    final transport = _ScriptedTransport([
      _text('「별」에서 시작해 5행과 10행의 별을 나란히 놓았어요. 마지막에는 바람에 스치는 별로 돌아갔어요.'),
    ]);

    final result = await writerWith(transport).write(request);

    expect(result.text, startsWith('「별」에서 시작해'));
    expect(result.isFallback, isFalse);
    expect(callCount, 1);
  });

  test('대화 원본이 없으면 모델을 부르지 않는다 — S09에서 채우는 자리', () async {
    final transport = _ScriptedTransport([_text('부르면 안 되는 응답')]);

    final result = await writerWith(transport).write(
      const SummaryRequest(
        poemId: 'seosi',
        firstWord: '별',
        conversation: [], // 공개 문서에는 대화 원본이 없다
        interpretation: '별은 멀리 있어서 오래 보게 되는 것 같다.',
      ),
    );

    expect(transport.requests, isEmpty);
    expect(result.isFallback, isTrue);
    expect(callCount, 0);
  });

  test('재료에 대화와 최종 해석이 들어간다', () async {
    final transport = _ScriptedTransport([_text('「별」에서 시작한 대화예요.')]);

    await writerWith(transport).write(request);

    final user = userOf(transport.requests.single);
    expect(user, contains('사용자: 10행이요. 바람에 스치운다는 말이 오래 남았어요.'));
    expect(user, contains('별은 멀리 있어서 오래 보게 되는 것 같다.'));
    expect(user, contains('첫 낱말: 별'));
    expect(transport.requests.single['tool_choice'], 'none');
  });

  test('호출이 실패하면 사실 문장으로 대신한다', () async {
    final transport = _ScriptedTransport([_error(429, '한도 초과')]);

    final result = await writerWith(transport).write(request);

    expect(result.text, fallbackText);
    expect(result.isFallback, isTrue);
  });

  test('물음표가 있으면 다시 쓰게 하고, 고쳐 오면 그것을 쓴다', () async {
    final transport = _ScriptedTransport([
      _text('「별」에서 시작해 10행으로 갔어요. 다음엔 어디를 볼까요?'),
      _text('「별」에서 시작해 10행으로 갔어요.'),
    ]);

    final result = await writerWith(transport).write(request);

    expect(result.text, '「별」에서 시작해 10행으로 갔어요.');
    expect(result.isFallback, isFalse);
    expect(userOf(transport.requests.last), contains('물음표가 있음'));
  });

  test('해석을 평가하는 말은 끝내 쓰지 않는다 — 공개 글에 순위를 붙이지 않는다', () async {
    final transport = _ScriptedTransport([
      _text('「별」에서 시작한 깊은 읽기였어요.'),
      _text('「별」에서 시작한 훌륭한 대화예요.'),
    ]);

    final result = await writerWith(transport).write(request);

    expect(result.text, fallbackText);
    expect(result.isFallback, isTrue);
  });

  test('대화에 없는 말을 따옴표에 넣으면 쓰지 않는다', () async {
    final transport = _ScriptedTransport([
      _text("'별이 무너지는 소리'를 오래 들었어요."),
      _text("'밤마다 별을 세었다'고 적었어요."),
    ]);

    final result = await writerWith(transport).write(request);

    expect(result.isFallback, isTrue);
  });
}
