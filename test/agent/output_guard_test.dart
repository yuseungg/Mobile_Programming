// 출력 필터 (A) — 기획서 6장 「모델 출력 제어」
import 'package:flutter_test/flutter_test.dart';
import 'package:yeobaek/agent/output_guard.dart';
import 'package:yeobaek/agent/prompts/fallback_questions.dart';

void main() {
  test('PoC에서 무료 모델이 실제로 낸 응답은 걸린다', () {
    const response = '해당 구절은 원문에 없습니다. '
        "시에서 '별'이 나오는 행은 5행의 \"별을 노래하는 마음으로\"와 "
        '10행의 "오늘 밤에도 별이 바람에 스치운다"입니다. '
        '그 중 어느 행에서 유래한 것인지, 아니면 다른 표현을 생각하고 계신 것인지 '
        '알려주시겠습니다 더 잘 도와드릴 수 있을 것 같습니다.';
    final result = OutputGuard.check(response);
    expect(result.isPassed, isFalse);
    expect(
      result.violations,
      containsAll([GuardViolation.notQuestion, GuardViolation.assertive]),
    );
  });

  test('기획서의 예시 응답은 통과한다', () {
    expect(
      OutputGuard.check(
        "그 표현은 이 시에 없어요. '별'이 나오는 건 5행과 10행인데, 둘 중 어느 쪽이었을까요?",
      ).isPassed,
      isTrue,
    );
    expect(
      OutputGuard.check(
        "그 구절이면 그렇게 읽을 수 있죠. 사랑하는 대상이 '모든 죽어가는 것'이라는 점도 같이 보면 어때요?",
      ).isPassed,
      isTrue,
    );
  });

  test('한 번에 둘 이상 물으면 걸린다', () {
    expect(
      OutputGuard.check('5행이 좋았나요? 10행은 어땠나요?').violations,
      contains(GuardViolation.multipleQuestions),
    );
  });

  test('세 문장을 넘으면 걸린다', () {
    expect(
      OutputGuard.check('좋아요. 그렇군요. 저도 봤어요. 어느 행이었나요?').violations,
      contains(GuardViolation.tooLong),
    );
  });

  test('단정형은 걸리고, 되묻는 말(…고)은 통과한다', () {
    expect(
      OutputGuard.check('이 행은 부끄러움을 상징한다. 어떻게 느꼈나요?').violations,
      contains(GuardViolation.assertive),
    );
    expect(
      OutputGuard.check('좋은 관찰입니다. 어느 행이었나요?').violations,
      contains(GuardViolation.assertive),
    );
    expect(OutputGuard.check('이 행이 무엇을 상징한다고 느꼈나요?').isPassed, isTrue);
  });

  test('앱에서 쓰지 않는 말이 들어가면 걸린다', () {
    for (final word in OutputGuard.forbiddenWords) {
      expect(
        OutputGuard.check('$word에 가까운 행은 어디일까요?').violations,
        contains(GuardViolation.forbiddenWord),
      );
    }
  });

  test('따옴표 안의 물음표와 문장은 세지 않는다', () {
    expect(
      OutputGuard.check("'왜 그랬을까? 모르겠다.'라고 쓰셨는데, 어느 행에서 그런 물음이 생겼나요?").isPassed,
      isTrue,
    );
  });

  test('빈 응답은 걸린다', () {
    expect(OutputGuard.check('  \n ').violations, [GuardViolation.empty]);
  });

  test('clean은 앞뒤 빈 줄과 강조 기호를 정리한다', () {
    expect(OutputGuard.clean('\n\n**5행**에서 무엇이 보이나요?\n'), '5행에서 무엇이 보이나요?');
  });

  test('준비된 관찰 질문은 모두 필터를 통과한다', () {
    final questions = [
      for (final list in fallbackQuestions.values) ...list,
      ...generalFallbackQuestions,
      openingFallbackQuestion('부끄러움'),
    ];
    for (final question in questions) {
      expect(OutputGuard.check(question).isPassed, isTrue, reason: question);
    }
  });
}
