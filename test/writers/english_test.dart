// 주인: D — 화면이 EN일 때 비교 문장 · 대화 요약도 영어로 (지시문 · 검사)
import 'package:flutter_test/flutter_test.dart';
import 'package:yeobaek/app/language.dart';
import 'package:yeobaek/data/fakes/fake_data.dart';
import 'package:yeobaek/data/models/chat_message.dart';
import 'package:yeobaek/data/models/expert_interpretation.dart';
import 'package:yeobaek/data/models/settings.dart';
import 'package:yeobaek/writers/comparison_guard.dart';
import 'package:yeobaek/writers/comparison_prompt.dart';
import 'package:yeobaek/writers/comparison_writer.dart';
import 'package:yeobaek/writers/quote_check.dart';
import 'package:yeobaek/writers/summary_guard.dart';
import 'package:yeobaek/writers/summary_prompt.dart';
import 'package:yeobaek/writers/summary_writer.dart';

void main() {
  final seosi = FakeData.poemById('seosi');
  final expertA = FakeData.expertInterpretations['seosi']!.first;

  final comparison = ComparisonRequest(
    poem: seosi,
    myInterpretation: '6행에서 멈췄다.',
    myEvidenceLines: const [6],
    expert: expertA,
    relation: Relation.partialOverlap,
    expertIndex: 0,
  );

  const summary = SummaryRequest(
    poemId: 'seosi',
    firstWord: '별',
    conversation: [
      ChatMessage(role: ChatRole.assistant, text: "Which line with '별' caught your eye first?"),
      ChatMessage(role: ChatRole.user, text: 'Line 10. 바람에 스치운다 stayed with me.'),
    ],
    interpretation: '바람 속에서도 별을 본다.',
    language: AppLanguage.en,
  );

  setUp(() => appLanguage.value = AppLanguage.en);
  tearDown(() => appLanguage.value = AppLanguage.ko);

  group('비교 문장', () {
    String systemOf(List<Map<String, Object?>> messages) => '${messages.first['content']}';
    String materialsOf(List<Map<String, Object?>> messages) => '${messages.last['content']}';

    test('EN이면 영어로 쓰라고 하고, 재료는 원문 그대로 준다', () {
      final messages = buildComparisonMessages(request: comparison, tone: Tone.plain);
      expect(systemOf(messages), contains('Write in English.'));
      expect(systemOf(messages), contains('"We started from the same line"'));
      expect(materialsOf(messages), contains('Line 6: 모든 죽어가는 것을 사랑해야지'));
      expect(materialsOf(messages), contains('Evidence lines: Line 6'));
      expect(materialsOf(messages), contains(expertA.stance));
    });

    test('KR이면 그대로 한국어', () {
      appLanguage.value = AppLanguage.ko;
      final messages = buildComparisonMessages(request: comparison, tone: Tone.plain);
      expect(systemOf(messages), contains('관계는 이미 정해져 있다'));
      expect(materialsOf(messages), contains('근거 행: 6행'));
    });

    test('인용 안에 축약형이 있어도 인용 검사가 꺼지지 않는다 (#55 리뷰)', () {
      expect(quotesIn("The poem says 'don't look back' at the end."), ["don'tlookback"]);
      expect(quotesIn("'It's all over' is what the line says."), ["It'sallover"]);
      expect(quotesIn("This reading doesn't take 'the night wind' lightly."), ['thenightwind']);
      expect(quotesIn("It's close to 'a star' and it isn't far."), ['astar']);
      expect(quotesIn("이 해석은 '별을 노래하는 마음으로'에 머문다."), ['별을노래하는마음으로']);
      // 원문에 없는 축약형 인용은 걸린다
      expect(quotesAreGrounded("The poem says 'don't look back' at the end.", seosi.lines),
          isFalse);
    });

    test('영어 비교 문장 — 통과하는 것과 걸리는 것', () {
      List<ComparisonViolation> check(String text) =>
          ComparisonGuard.check(text, comparison);

      expect(check("Both readings pass through line 6, where '모든 죽어가는 것을 사랑해야지' sits. "
          "It's where they meet, and they don't need to agree beyond it."), isEmpty);
      expect(check('Both readings start from lines 2 and 6.'), isEmpty);
      expect(check('Both readings meet at line 99.'),
          contains(ComparisonViolation.unknownLine));
      expect(check('Both readings meet at lines 6 and 99.'),
          contains(ComparisonViolation.unknownLine));
      expect(check('The wind in line 6 symbolizes hardship.'),
          contains(ComparisonViolation.assertive));
      expect(check('Your reading is the correct one.'),
          contains(ComparisonViolation.forbiddenWord));
      expect(check("Both readings see 'the wind of trials' in line 6."),
          contains(ComparisonViolation.unknownQuote)); // 번역을 따옴표에 넣으면 안 된다
    });

    test('다시 쓰기 안내도 영어', () {
      expect(comparisonRewriteInstruction([ComparisonViolation.unknownLine]),
          contains('line number the poem does not have'));
    });
  });

  group('대화 요약', () {
    test('영어 요청이면 영어로 쓰라고 하고 글자 수를 넉넉히 준다', () {
      final messages =
          buildSummaryMessages(request: summary, poem: seosi, tone: Tone.gentle);
      final system = '${messages.first['content']}';
      final materials = '${messages.last['content']}';
      expect(system, contains('Write in English.'));
      expect(system, contains('${SummaryGuard.maxCharsEnglish} characters'));
      expect(SummaryGuard.maxCharsOf(summary), 280);
      expect(materials, contains('User: Line 10.'));
    });

    test('화면 언어가 아니라 요청의 언어를 따른다 — S06이 한/영 두 벌을 따로 청한다', () {
      final korean = SummaryRequest(
        poemId: summary.poemId,
        firstWord: summary.firstWord,
        conversation: summary.conversation,
        interpretation: summary.interpretation,
        language: AppLanguage.ko,
      );
      // 화면은 EN (setUp)이어도 한국어 요청은 한국어로
      final system = '${buildSummaryMessages(request: korean, poem: seosi, tone: Tone.plain).first['content']}';
      expect(system, contains('규칙'));
      expect(system, isNot(contains('Write in English.')));
      expect(SummaryGuard.maxCharsOf(korean), 150);
      expect(summaryRewriteInstruction([SummaryViolation.evaluative], korean),
          contains('해석을 평가하는 말'));

      // 화면이 KR이어도 영어 요청은 영어로
      appLanguage.value = AppLanguage.ko;
      final english = '${buildSummaryMessages(request: summary, poem: seosi, tone: Tone.plain).first['content']}';
      expect(english, contains('Write in English.'));
    });

    test('영어 요약 — 통과하는 것과 걸리는 것', () {
      List<SummaryViolation> check(String text) => SummaryGuard.check(text, summary);

      expect(check("It began with '별' and settled on line 10, where '바람에 스치운다' stayed with the reader."),
          isEmpty);
      expect(check('An insightful reading that began with the star.'),
          contains(SummaryViolation.evaluative));
      expect(check('It began with the star. Where did it go?'),
          contains(SummaryViolation.question));
      expect(check('It began with the star, which represents hope.'),
          contains(SummaryViolation.assertive));
      expect(check('It reached the right answer in the end.'),
          contains(SummaryViolation.forbiddenWord));
      expect(check('a' * 281), contains(SummaryViolation.tooLong));
    });

    test('다시 쓰기 안내도 영어', () {
      expect(summaryRewriteInstruction([SummaryViolation.evaluative], summary),
          contains('it judged the interpretation'));
    });
  });
}
