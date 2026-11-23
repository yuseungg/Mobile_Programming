// 주인: A — 화면이 EN일 때 질문 모델도 영어로 (지시문 · 출력 필터 · 준비된 질문 · 행 번호)
import 'package:flutter_test/flutter_test.dart';
import 'package:yeobaek/agent/fake_chat_agent.dart';
import 'package:yeobaek/agent/output_guard.dart';
import 'package:yeobaek/agent/prompts/fallback_questions.dart';
import 'package:yeobaek/agent/prompts/system_prompt.dart';
import 'package:yeobaek/agent/tools/agent_tools.dart';
import 'package:yeobaek/agent/tools/poem_text.dart';
import 'package:yeobaek/app/language.dart';
import 'package:yeobaek/data/fakes/fake_data.dart';
import 'package:yeobaek/data/models/chat_message.dart';
import 'package:yeobaek/data/models/settings.dart';

void main() {
  final seosi = FakeData.poemById('seosi');

  tearDown(() => appLanguage.value = AppLanguage.ko);

  group('지시문', () {
    test('KR이면 한국어 지시문 — 그대로다', () {
      final prompt = buildSystemPrompt(seosi, Tone.plain);
      expect(prompt, contains('너는 시를 혼자 읽도록 돕는 질문자다'));
      expect(prompt, contains('1행: 죽는 날까지 하늘을 우러러'));
      expect(prompt, isNot(contains('English')));
    });

    test('EN이면 영어로 답하라고 하고, 시는 원문 그대로 준다', () {
      appLanguage.value = AppLanguage.en;
      final prompt = buildSystemPrompt(seosi, Tone.gentle, isSaved: true);
      expect(prompt, contains('Always reply in English'));
      expect(prompt, contains('Line 1: 죽는 날까지 하늘을 우러러'));
      expect(prompt, contains('Never put your own translation inside quotation marks'));
      expect(prompt, contains('After the interpretation is saved'));
      expect(prompt, isNot(contains('너는')));
    });

    test('EN이면 첫 질문 · 힌트 · 다시 쓰기 안내도 영어', () {
      appLanguage.value = AppLanguage.en;
      expect(openingInstruction('별'), contains('"별"'));
      expect(openingInstruction('별'), startsWith('(App note)'));
      expect(hintInstruction(''), startsWith('(App note)'));
      expect(hintInstruction('Which line?'), contains('"Which line?"'));
      expect(rewriteInstruction([GuardViolation.notQuestion]),
          contains('did not end with a question mark'));
    });

    test('EN이면 툴 설명도 영어 — 이름과 인자는 그대로', () {
      appLanguage.value = AppLanguage.en;
      final tools = AgentTools(poem: seosi, isSaved: true);
      final functions = [
        for (final definition in tools.definitions)
          definition['function']! as Map<String, Object?>,
      ];
      expect(functions.map((function) => function['name']), [
        AgentTools.verifyQuoteName,
        AgentTools.searchPoemLinesName,
        AgentTools.compareWithExpertsName,
        AgentTools.getPoemContextName,
      ]);
      for (final function in functions) {
        expect('${function['description']}', isNot(contains('한다')));
      }
      expect(tools.run('nothing', {}).output['error'], 'No such tool: nothing');
    });
  });

  group('출력 필터 — 영어', () {
    bool passes(String text) => OutputGuard.check(text).isPassed;
    List<GuardViolation> violations(String text) =>
        OutputGuard.check(text).violations;

    test('질문 하나로 끝나는 영어 응답은 통과한다', () {
      expect(passes('Which word in line 5 stayed with you the longest?'), isTrue);
      expect(passes("You kept the word '별'. Which line brought it to mind?"), isTrue);
    });

    test('되묻는 문장 안의 뜻 말은 단정이 아니다', () {
      expect(passes('What do you think the wind in line 10 represents?'), isTrue);
    });

    test('뜻을 못박는 문장은 단정형', () {
      expect(violations('The wind represents hardship. What do you feel?'),
          contains(GuardViolation.assertive));
      expect(violations('This poem is about shame. Which line shows it?'),
          contains(GuardViolation.assertive));
    });

    test('쓰지 않는 말 — 영어도 대소문자 없이', () {
      for (final text in [
        'Is that the correct reading?',
        'What is the Answer here?',
        'Do you want an explanation?',
        'Shall I give some commentary?',
      ]) {
        expect(violations(text), contains(GuardViolation.forbiddenWord), reason: text);
      }
    });

    test("영어 낱말 사이의 작은따옴표(don't · it's)는 인용이 아니다", () {
      // 따옴표로 잘못 읽으면 두 물음표 중 하나가 「인용 안」으로 사라진다
      expect(violations("What's in line 5? Where's the wind?"),
          contains(GuardViolation.multipleQuestions));
      expect(passes("It's a long line. Which word don't you want to let go of?"), isTrue);
    });

    test('한국어 검사는 그대로다', () {
      expect(violations('바람은 시련을 상징한다. 어떻게 느꼈나요?'),
          contains(GuardViolation.assertive));
      expect(violations('정답은 무엇일까요?'), contains(GuardViolation.forbiddenWord));
    });
  });

  group('준비된 관찰 질문', () {
    test('EN이면 영어 질문 — 모두 필터를 통과한다', () {
      appLanguage.value = AppLanguage.en;
      final questions = [
        for (final list in englishFallbackQuestions.values) ...list,
        ...generalEnglishFallbackQuestions,
        openingFallbackQuestion('부끄러움'),
        openingFallbackQuestion(''),
      ];
      for (final question in questions) {
        expect(OutputGuard.check(question).isPassed, isTrue, reason: question);
      }
      expect(nextFallbackQuestion('seosi', const []),
          englishFallbackQuestions['seosi']!.first);
    });

    test('EN이면 힌트도 영어 — 모두 필터를 통과한다', () {
      appLanguage.value = AppLanguage.en;
      final hints = [
        for (final list in englishPreparedQuestions.values)
          for (final prepared in list) prepared.hint,
        for (final prepared in generalEnglishPreparedQuestions) prepared.hint,
        englishFollowUpHint,
      ];
      for (final hint in hints) {
        expect(OutputGuard.check(hint).isPassed, isTrue, reason: hint);
      }
    });

    test('힌트는 직전 질문의 짝 — 대화 중에 언어를 바꿔도 지금 언어로', () {
      final koreanQuestion = preparedQuestions['seosi']![1].question;
      final conversation = [
        ChatMessage(role: ChatRole.assistant, text: koreanQuestion),
      ];
      appLanguage.value = AppLanguage.en; // 한국어로 질문받은 뒤 EN으로 바꿈
      expect(fallbackHint('seosi', conversation),
          englishPreparedQuestions['seosi']![1].hint);

      final englishConversation = [
        ChatMessage(
            role: ChatRole.assistant,
            text: englishPreparedQuestions['seosi']![1].question),
      ];
      appLanguage.value = AppLanguage.ko; // 영어로 질문받은 뒤 KR로 바꿈
      expect(fallbackHint('seosi', englishConversation),
          preparedQuestions['seosi']![1].hint);

      appLanguage.value = AppLanguage.en;
      expect(
        fallbackHint('seosi', [
          ChatMessage(role: ChatRole.assistant, text: 'A question the model wrote?'),
        ]),
        englishFollowUpHint,
      );
    });

    test('시마다 한국어와 같은 수', () {
      for (final poemId in fallbackQuestions.keys) {
        expect(englishFallbackQuestions[poemId]?.length,
            fallbackQuestions[poemId]!.length, reason: poemId);
      }
      expect(generalEnglishPreparedQuestions.length,
          generalPreparedQuestions.length);
    });
  });

  group('행 번호 읽기', () {
    test('영어 "line N" · "lines A and B"도 읽는다', () {
      expect(lineNosMentioned('What do you see in line 6?', seosi), [6]);
      expect(lineNosMentioned('Lines 2 and 6, or line 10?', seosi), [2, 6, 10]);
      expect(lineNosMentioned('lines 5, 10', seosi), [5, 10]);
    });

    test('시에 없는 행 · 빈 줄은 빼는 규칙은 같다', () {
      expect(lineNosMentioned('line 99 and line 9', seosi), isEmpty); // 9행은 빈 줄
    });
  });

  group('가짜 에이전트 (키 없을 때)', () {
    final agent = FakeChatAgent(delay: Duration.zero);
    ChatMessage user(String text) => ChatMessage(role: ChatRole.user, text: text);

    test('EN이면 영어로 되묻고, 실제로 나오는 행을 가리킨다', () async {
      appLanguage.value = AppLanguage.en;
      final reply = await agent.reply(
        poem: seosi,
        conversation: [user("It's because of '별을 그리워하며', I don't know why.")],
      );
      expect(reply.text, contains("isn't in this poem"));
      expect(reply.text, contains('lines 5 and 10'));
      expect(OutputGuard.check(reply.text).isPassed, isTrue, reason: reply.text);
    });

    test('EN이면 첫 질문도 영어', () async {
      appLanguage.value = AppLanguage.en;
      final reply = await agent.open(poem: seosi, firstWord: '별');
      expect(reply.text, startsWith('You kept the word "별"'));
    });
  });
}
