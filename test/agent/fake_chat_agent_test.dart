// 가짜 에이전트 (A) — 키 없이 S05를 확인할 때 붙는다
import 'package:flutter_test/flutter_test.dart';
import 'package:yeobaek/agent/fake_chat_agent.dart';
import 'package:yeobaek/agent/output_guard.dart';
import 'package:yeobaek/agent/prompts/fallback_questions.dart';
import 'package:yeobaek/data/fakes/fake_data.dart';
import 'package:yeobaek/data/models/chat_message.dart';

void main() {
  final seosi = FakeData.poemById('seosi');
  final agent = FakeChatAgent(delay: Duration.zero);

  ChatMessage user(String text) => ChatMessage(role: ChatRole.user, text: text);
  ChatMessage assistant(String text) =>
      ChatMessage(role: ChatRole.assistant, text: text);

  test('없는 구절을 인용하면 원문에 없다고 하고 별이 나오는 행을 가리킨다', () async {
    final reply = await agent.reply(
      poem: seosi,
      conversation: [user("'별을 그리워하며'라는 구절 때문에 그렇게 느꼈어요.")],
    );
    expect(reply.text, contains('5행과 10행'));
    expect(reply.evidenceLines, isEmpty);
    expect(reply.pointingLine, 5);
  });

  test('있는 구절을 인용하면 근거 행이 된다', () async {
    final reply = await agent.reply(
      poem: seosi,
      conversation: [user("'모든 죽어가는 것을 사랑해야지'가 좋았어요.")],
    );
    expect(reply.evidenceLines, [6]);
  });

  test('"N행"으로 짚으면 그 행이 근거 행이 된다', () async {
    final reply = await agent.reply(poem: seosi, conversation: [user('아, 5행이요.')]);
    expect(reply.evidenceLines, [5]);
  });

  test('첫 질문은 첫 낱말에서 출발한다', () async {
    final reply = await agent.open(poem: seosi, firstWord: '부끄러움');
    expect(reply.text, contains('부끄러움'));
  });

  test('힌트는 직전 질문의 짝 힌트다 — 감각 질문 뒤에 다른 주제로 넘어가지 않는다', () async {
    // 실기기 통합 확인에서 나온 경우: 준비된 질문이 없는 시, 마지막이 감각 질문
    final reply = await agent.hint(
      poem: FakeData.poemById('theroadnottaken'),
      conversation: [
        assistant(generalFallbackQuestions[2]),
        user('잘 모르겠어요'),
        assistant(generalFallbackQuestions[3]),
      ],
    );
    expect(reply.text, generalPreparedQuestions[3].hint);
  });

  test('직전 질문이 준비된 질문이 아니면 그 질문의 낱말에서 출발하는 힌트', () async {
    final reply = await agent.hint(
      poem: seosi,
      conversation: [assistant("'부끄러움'이라는 낱말이 남았군요. 어느 행을 읽을 때 그 낱말이 떠올랐나요?")],
    );
    expect(reply.text, followUpHint);
  });

  test('시마다 준비된 질문은 4개, 힌트는 질문과 다르다', () {
    for (final list in [...preparedQuestions.values, generalPreparedQuestions]) {
      expect(list, hasLength(4));
      for (final prepared in list) {
        expect(prepared.hint, isNot(prepared.question));
      }
    }
  });

  test('응답은 모두 출력 필터를 통과한다', () async {
    final replies = [
      await agent.open(poem: seosi, firstWord: ''),
      await agent.reply(poem: seosi, conversation: [user("'별을 그리워하며' 때문에요")]),
      await agent.reply(poem: seosi, conversation: [user("'하늘을 우러러'요")]),
      await agent.reply(poem: seosi, conversation: [user('6행이요')]),
      await agent.reply(poem: seosi, conversation: [user('잘 모르겠어요')]),
      await agent.hint(poem: seosi, conversation: const []),
    ];
    for (final reply in replies) {
      expect(OutputGuard.check(reply.text).isPassed, isTrue, reason: reply.text);
    }
  });
}
