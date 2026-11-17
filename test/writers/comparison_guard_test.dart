// 주인: D — 비교 문장 검사 (지침서 제품 원칙 6 「없는 것을 말하지 않는다」)
// 질문이 아니라 서술이므로 A의 OutputGuard와 보는 것이 다르다.
import 'package:flutter_test/flutter_test.dart';
import 'package:yeobaek/data/fakes/fake_data.dart';
import 'package:yeobaek/data/models/expert_interpretation.dart';
import 'package:yeobaek/writers/comparison_guard.dart';
import 'package:yeobaek/writers/comparison_writer.dart';

void main() {
  final seosi = FakeData.poemById('seosi');
  final expertA = FakeData.expertInterpretations['seosi']!.first;

  final request = ComparisonRequest(
    poem: seosi,
    myInterpretation: '6행에서 멈췄다.',
    myEvidenceLines: const [6],
    expert: expertA,
    relation: Relation.partialOverlap,
    expertIndex: 0,
  );

  List<ComparisonViolation> check(String text) =>
      ComparisonGuard.check(text, request);

  test('물음표로 끝나지 않아도 통과한다 — 비교 문장은 질문이 아니다', () {
    expect(check('두 읽기 모두 6행을 지나가요.'), isEmpty);
  });

  test('원문에 있는 구절 인용은 통과한다', () {
    expect(check("두 읽기 모두 '한 점 부끄럼이 없기를,'에서 멈춰요."), isEmpty);
  });

  test('행이 바뀌는 자리를 인용해도 통과한다 — 띄어쓰기로 막지 않는다', () {
    expect(
      check("'모든 죽어가는 것을 사랑해야지 그리고 나한테 주어진 길을'을 함께 봤어요."),
      isEmpty,
    );
  });

  test('전문가 주장을 인용하는 것도 재료 안이다', () {
    expect(check("전문가는 '괴로움을 통과한 뒤에 나온 다짐이다'로 읽어요."), isEmpty);
  });

  test('재료에 없는 말을 따옴표에 넣으면 걸린다', () {
    expect(
      check("'별빛이 쏟아지는 밤'에서 두 읽기가 만나요."),
      contains(ComparisonViolation.unknownQuote),
    );
  });

  test('한 글자 따옴표는 보지 않는다 — 이름표까지 막게 된다', () {
    expect(check('전문가 해석 "A"와 같은 줄에서 출발했어요.'), isEmpty);
  });

  test('시에 없는 행 번호는 걸린다 — 서시는 10행까지다', () {
    expect(check('11행에서 만나요.'), contains(ComparisonViolation.unknownLine));
    expect(check('10행에서 만나요.'), isEmpty);
  });

  test('쓰지 않는 말과 단정형이 걸린다', () {
    expect(
      check('이 해석이 정답에 가까워요.'),
      contains(ComparisonViolation.forbiddenWord),
    );
    expect(
      check('6행은 다짐을 상징한다.'),
      contains(ComparisonViolation.assertive),
    );
  });

  test('세 문장을 넘으면 걸린다', () {
    expect(
      check('하나요. 둘이요. 셋이요. 넷이요.'),
      contains(ComparisonViolation.tooLong),
    );
  });

  test('비어 있으면 그것만 알린다', () {
    expect(check('   '), [ComparisonViolation.empty]);
  });
}
