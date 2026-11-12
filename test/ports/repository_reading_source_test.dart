// 주인: D — 어댑터가 C의 저장소에서 읽는지 (가짜 저장소 위에서)
//
// 화면은 ReadingSource만 보므로, 여기서 증명해야 할 것은 하나다:
// 같은 인터페이스가 FakeData 직접 읽기 대신 Repositories를 거쳐도 같은 답을 준다.

import 'package:flutter_test/flutter_test.dart';
import 'package:yeobaek/data/fakes/fake_data.dart';
import 'package:yeobaek/data/repositories.dart';
import 'package:yeobaek/ports/fake_reading_source.dart';
import 'package:yeobaek/ports/reading_source.dart';
import 'package:yeobaek/ports/repository_reading_source.dart';

void main() {
  const source = RepositoryReadingSource();

  group('로그인한 뒤', () {
    setUp(() => Repositories.useFakes(signedInUserId: FakeData.myUserId));

    test('내 사용자 id는 계정 저장소에서 온다', () {
      expect(source.myUserId, FakeData.myUserId);
    });

    test('내 읽기를 읽기 저장소에서 가져온다', () async {
      final mine = await source.readingFor(FakeData.todayPoemId);
      expect(mine, isNotNull);
      expect(mine!.poemId, FakeData.todayPoemId);
    });

    test('프로필을 프로필 저장소에서 가져온다', () async {
      final profile = await source.profileById(FakeData.myUserId);
      expect(profile.userId, FakeData.myUserId);
      expect(profile.nickname, isNotEmpty);
    });

    test('공개 대화를 공개 대화 저장소에서 가져온다', () async {
      final list = await source.conversationsFor(FakeData.todayPoemId);
      expect(list, isNotEmpty);
      expect(list.every((c) => c.poemId == FakeData.todayPoemId), isTrue);
      final one = await source.conversationById(list.first.conversationId);
      expect(one.conversationId, list.first.conversationId);
    });

    test('가짜 구현과 같은 답을 준다 — 화면이 구별할 수 없다', () async {
      const fake = FakeReadingSource();
      expect(source.todayPoemId, fake.todayPoemId);
      expect((await source.poems()).length, (await fake.poems()).length);
      expect(
        (await source.expertsFor('seosi')).length,
        (await fake.expertsFor('seosi')).length,
      );
      expect(
        (await source.conversationsFor(FakeData.todayPoemId)).length,
        (await fake.conversationsFor(FakeData.todayPoemId)).length,
      );
    });
  });

  group('로그인 전에는 (로그인 분기가 들어오기 전까지의 임시 동작)', () {
    setUp(() => Repositories.useFakes());

    test('가짜 사용자 id로 둔다 — A · B 화면과 같은 방식', () {
      // 이래야 1단계 시연에서 읽기 → 저장 → 대조가 이어진다.
      // 로그인 분기가 들어오면 이 폴백과 이 테스트를 함께 지운다.
      expect(source.myUserId, FakeData.myUserId);
    });

    test('그 id로 내 읽기를 찾는다', () async {
      expect(await source.readingFor(FakeData.todayPoemId), isNotNull);
    });

    test('시 본문과 전문가 해석도 읽힌다 (번들 콘텐츠)', () async {
      expect(await source.poems(), isNotEmpty);
      expect(await source.expertsFor('seosi'), isNotEmpty);
    });
  });

  group('대조 열람 알림', () {
    setUp(() => Repositories.useFakes(signedInUserId: FakeData.myUserId));

    test('저장한 시는 대조를 열면 해석이 잠긴다', () async {
      const poemId = 'seosi';
      expect((await source.readingFor(poemId))!.hasOpenedComparison, isFalse);

      await source.markComparisonOpened(poemId);

      expect((await source.readingFor(poemId))!.hasOpenedComparison, isTrue);
    });

    test('저장하지 않은 시에 불러도 던지지 않는다 — 대조는 보여야 한다', () async {
      await expectLater(source.markComparisonOpened('jindallae'), completes);
    });
  });

  test('ReadingSource를 구현한다', () {
    expect(source, isA<ReadingSource>());
  });
}
