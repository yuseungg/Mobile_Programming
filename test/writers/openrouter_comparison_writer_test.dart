// 주인: D — 비교 문장을 모델에게 쓰게 하는 쪽 (기획서 4장 · 요건 (a) 둘째 화면)
// 네트워크 대신 정해진 응답을 차례로 돌려주는 가짜 전송을 끼운다.
// 무료 한도를 쓰지 않고 확인한다 (A의 에이전트 테스트와 같은 방식).
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:yeobaek/agent/openrouter_client.dart';
import 'package:yeobaek/agent/cancel_token.dart';
import 'package:yeobaek/agent/transport/http_types.dart';
import 'package:yeobaek/data/fakes/fake_data.dart';
import 'package:yeobaek/data/models/expert_interpretation.dart';
import 'package:yeobaek/data/models/settings.dart';
import 'package:yeobaek/writers/comparison_writer.dart';
import 'package:yeobaek/writers/fake_comparison_writer.dart';
import 'package:yeobaek/writers/openrouter_comparison_writer.dart';

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
  final seosi = FakeData.poemById('seosi');
  // 근거 2 · 6 · 7 · 8행. 내 근거 [6]과 만나 partialOverlap이 된다
  final expertA = FakeData.expertInterpretations['seosi']!.first;

  const prewritten = FakeComparisonWriter(prewritten: {
    'seosi': ['미리 쓴 비교 문장'],
  });

  ComparisonRequest requestFor(ExpertInterpretation expert) => ComparisonRequest(
        poem: seosi,
        myInterpretation: '6행에서 멈췄다. 사랑해야지, 라는 말이 다짐처럼 들렸다.',
        myEvidenceLines: const [6],
        expert: expert,
        relation: Relation.partialOverlap,
        expertIndex: 0,
      );

  var callCount = 0;
  OpenRouterComparisonWriter writerWith(_ScriptedTransport transport) {
    callCount = 0;
    return OpenRouterComparisonWriter(
      client: OpenRouterClient(apiKey: 'test-key', postJson: transport.post),
      model: 'test/model',
      tone: Tone.plain,
      fallback: prewritten,
      onModelCall: () async => callCount++,
    );
  }

  String systemOf(Map<String, Object?> request) =>
      ((request['messages'] as List).first as Map)['content'] as String;

  String userOf(Map<String, Object?> request) => [
        for (final message in request['messages'] as List)
          if ((message as Map)['role'] == 'user') '${message['content']}',
      ].join('\n');

  test('모델이 쓴 문장을 그대로 쓴다 — 폴백이 아니다', () async {
    final transport = _ScriptedTransport([
      _text('두 읽기 모두 6행을 지나가요. 한쪽은 괴로움 뒤의 다짐으로, 한쪽은 멈춤으로 읽어요.'),
    ]);

    final result = await writerWith(transport).write(requestFor(expertA));

    expect(result.text, startsWith('두 읽기 모두 6행을 지나가요'));
    expect(result.isFallback, isFalse);
    expect(transport.requests, hasLength(1));
    expect(callCount, 1); // 사용량을 한 번 센다
  });

  test('관계는 코드가 정한 것을 프롬프트에 박아 넣는다 — 모델이 다시 판단하지 않는다', () async {
    final transport = _ScriptedTransport([_text('두 읽기 모두 6행을 지나가요.')]);

    await writerWith(transport).write(requestFor(expertA));

    final system = systemOf(transport.requests.single);
    expect(system, contains('같은 줄에서 출발했어요'));
    expect(system, contains('다시 판단하거나 뒤집지 않는다'));
    // 툴은 쓰지 않는다 — 재료는 코드가 다 모아 넘긴다
    expect(transport.requests.single['tools'], isNull);
    expect(transport.requests.single['tool_choice'], 'none');
  });

  test('재료에 내 해석 · 전문가 주장 · 함께 본 행이 들어간다', () async {
    final transport = _ScriptedTransport([_text('두 읽기 모두 6행을 지나가요.')]);

    await writerWith(transport).write(requestFor(expertA));

    final user = userOf(transport.requests.single);
    expect(user, contains('사랑해야지, 라는 말이 다짐처럼 들렸다'));
    expect(user, contains('괴로움을 통과한 뒤에 나온 다짐이다'));
    expect(user, contains('함께 본 행: 6행'));
    expect(user, contains('6행: 모든 죽어가는 것을 사랑해야지'));
  });

  test('호출이 실패하면 미리 쓴 문장으로 대신하고 다시 부르지 않는다', () async {
    final transport = _ScriptedTransport([_error(429, '한도 초과')]);

    final result = await writerWith(transport).write(requestFor(expertA));

    // 관계 한 줄 뒤에 미리 쓴 문장이 붙는다 — 미리 쓴 쪽은 전문가만 설명한다
    expect(result.text, endsWith('미리 쓴 비교 문장'));
    expect(result.isFallback, isTrue);
    expect(transport.requests, hasLength(1));
  });

  test('쓰지 않는 말이 있으면 다시 쓰게 하고, 고쳐 오면 그것을 쓴다', () async {
    final transport = _ScriptedTransport([
      _text('이 해석이 정답에 더 가까워요.'),
      _text('두 읽기 모두 6행을 지나가요.'),
    ]);

    final result = await writerWith(transport).write(requestFor(expertA));

    expect(result.text, '두 읽기 모두 6행을 지나가요.');
    expect(result.isFallback, isFalse);
    expect(transport.requests, hasLength(2));
    expect(userOf(transport.requests.last), contains('쓰지 않는 말이 있음'));
    expect(callCount, 2);
  });

  test('시에 없는 구절을 따옴표에 넣으면 끝내 쓰지 않는다 — 미리 쓴 문장으로 간다', () async {
    final transport = _ScriptedTransport([
      _text("'별빛이 쏟아지는 밤'이라는 구절에서 두 읽기가 만나요."),
      _text("'밤마다 별이 무너진다'는 자리에서 두 읽기가 만나요."),
    ]);

    final result = await writerWith(transport).write(requestFor(expertA));

    // 관계 한 줄 뒤에 미리 쓴 문장이 붙는다 — 미리 쓴 쪽은 전문가만 설명한다
    expect(result.text, endsWith('미리 쓴 비교 문장'));
    expect(result.isFallback, isTrue);
    // 다시 쓰기는 한 번만 (한 화면에 전문가 수만큼 불리므로)
    expect(transport.requests, hasLength(2));
  });

  test('원문에 있는 구절을 인용한 문장은 통과한다', () async {
    final transport = _ScriptedTransport([
      _text("두 읽기 모두 '모든 죽어가는 것을 사랑해야지'에서 멈춰요."),
    ]);

    final result = await writerWith(transport).write(requestFor(expertA));

    expect(result.isFallback, isFalse);
  });

  test('시에 없는 행 번호를 부르면 쓰지 않는다', () async {
    final transport = _ScriptedTransport([
      _text('11행에서 두 읽기가 만나요.'), // 서시는 10행까지다
      _text('12행에서 두 읽기가 만나요.'),
    ]);

    final result = await writerWith(transport).write(requestFor(expertA));

    expect(result.isFallback, isTrue);
  });
}
