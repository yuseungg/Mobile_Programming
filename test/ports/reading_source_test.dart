// 주인: D — 읽기 포트 (lib/ports/)
// 화면은 이 인터페이스만 본다. C의 저장소가 나오면 구현체를 하나 더 끼운다.
import 'package:flutter_test/flutter_test.dart';
import 'package:yeobaek/ports/fake_reading_source.dart';

void main() {
  const source = FakeReadingSource();

  test('수록된 시를 모두 돌려준다', () async {
    final poems = await source.poems();
    expect(poems, hasLength(3));
    expect(poems.map((p) => p.poemId), containsAll(['seosi', 'jindallae']));
  });

  test('오늘의 시와 내 uid', () async {
    expect(source.todayPoemId, 'seosi');
    expect(source.myUserId, isNotEmpty);
  });

  test('읽지 않은 시의 내 읽기는 null', () async {
    expect(await source.readingFor('bomgoyangi'), isNull);
  });

  test('저장한 시의 내 읽기는 isSaved가 참', () async {
    final reading = await source.readingFor('seosi');
    expect(reading, isNotNull);
    expect(reading!.isSaved, isTrue);
  });

  test('전문가 해석은 에셋에서 읽는다 — 서시는 둘', () async {
    final experts = await source.expertsFor('seosi');
    expect(experts, hasLength(2));
    expect(experts[0].label, '전문가 해석 A');
  });

  test('해석이 아직 없는 시는 빈 목록 — S07이 「준비 중」을 띄운다', () async {
    expect(await source.expertsFor('bomgoyangi'), isEmpty);
  });

  test('공개 대화는 그 시의 것만', () async {
    final conversations = await source.conversationsFor('seosi');
    expect(conversations, isNotEmpty);
    expect(conversations.every((c) => c.poemId == 'seosi'), isTrue);
  });

  test('비교 문장은 전문가 해석과 같은 수', () async {
    final texts = await source.comparisonTextsFor('seosi');
    final experts = await source.expertsFor('seosi');
    expect(texts, hasLength(experts.length));
  });
}
