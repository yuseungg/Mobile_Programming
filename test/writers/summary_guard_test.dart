// 주인: D — 요약 검사 (기획서 F7 · 지침서 제품 원칙 3 「해석의 질로 순위를 주지 않는다」 · 6)
// 요약은 남이 읽는 글이라 비교 문장보다 엄하다.
import 'package:flutter_test/flutter_test.dart';
import 'package:yeobaek/app/language.dart';
import 'package:yeobaek/data/models/chat_message.dart';
import 'package:yeobaek/writers/summary_guard.dart';
import 'package:yeobaek/writers/summary_writer.dart';

void main() {
  const request = SummaryRequest(
    poemId: 'seosi',
    firstWord: '별',
    conversation: [
      ChatMessage(
        role: ChatRole.assistant,
        text: "'별'이 나오는 행은 5행과 10행인데, 어느 쪽이 먼저 눈에 들어왔나요?",
      ),
      ChatMessage(role: ChatRole.user, text: '10행이요. 바람에 스치운다는 말이 오래 남았어요.'),
    ],
    interpretation: '별은 멀리 있어서 오래 보게 되는 것 같다.',
    language: AppLanguage.ko,
  );

  List<SummaryViolation> check(String text) =>
      SummaryGuard.check(text, request);

  test('사실만 적은 두 문장은 통과한다', () {
    expect(check('「별」에서 시작해 5행과 10행을 나란히 놓았어요. 바람에 스치는 쪽에 오래 머물렀어요.'),
        isEmpty);
  });

  test('대화에 있던 말을 인용하는 것은 통과한다', () {
    expect(check("'바람에 스치운다는 말이 오래 남았어요'로 끝난 대화예요."), isEmpty);
  });

  test('물음표가 있으면 걸린다 — 요약은 질문이 아니다', () {
    expect(
      check('「별」에서 시작했어요. 다음엔 어디를 볼까요?'),
      contains(SummaryViolation.question),
    );
  });

  test('해석을 평가하는 말은 걸린다 — 공개 글에 순위를 붙이지 않는다', () {
    expect(
      check('「별」에서 시작한 깊은 읽기였어요.'),
      contains(SummaryViolation.evaluative),
    );
    expect(
      check('조금 아쉬운 대화였어요.'),
      contains(SummaryViolation.evaluative),
    );
  });

  test('대화에 없는 말을 따옴표에 넣으면 걸린다', () {
    expect(
      check("'밤마다 별을 세었다'고 적었어요."),
      contains(SummaryViolation.unknownQuote),
    );
  });

  test('대화에 있던 말을 품은 더 긴 거짓 인용도 걸린다', () {
    expect(
      check("'바람에 스치운다는 말이 오래 남았고 울었어요'라고 했어요."),
      contains(SummaryViolation.unknownQuote),
    );
  });

  test('두 문장을 넘거나 150자를 넘으면 걸린다', () {
    expect(
      check('하나요. 둘이요. 셋이요.'),
      contains(SummaryViolation.tooLong),
    );
    expect(
      check('「별」에서 시작한 대화예요. ${'아' * 150}'),
      contains(SummaryViolation.tooLong),
    );
  });

  test('쓰지 않는 말과 단정형이 걸린다', () {
    expect(
      check('정답에 가까운 해석이에요.'),
      contains(SummaryViolation.forbiddenWord),
    );
    expect(
      check('별은 그리움을 상징한다.'),
      contains(SummaryViolation.assertive),
    );
  });

  test('비어 있으면 그것만 알린다', () {
    expect(check('  '), [SummaryViolation.empty]);
  });
}
