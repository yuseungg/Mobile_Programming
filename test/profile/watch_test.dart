// 주인: D — S12가 프로필을 구독하는지 (C의 UserRepository.watchProfile)
//
// 전에는 profileById로 한 번만 읽었다. 그래서 S06에서 저장해 뱃지를 받아도
// 이 화면을 닫고 다시 열어야 보였다. 그 상태로 돌아가면 이 테스트가 깨진다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yeobaek/app/strings.dart';
import 'package:yeobaek/data/fakes/fake_data.dart';
import 'package:yeobaek/data/models/reading.dart';
import 'package:yeobaek/data/models/user_profile.dart';
import 'package:yeobaek/data/repositories.dart';
import 'package:yeobaek/features/community/locked_notice.dart';
import 'package:yeobaek/features/profile/badge_image.dart';
import 'package:yeobaek/features/profile/profile_screen.dart';

import '../support/pump.dart';
import '../support/stub_reading_source.dart';

void main() {
  group('저장소 연결 (화면 기본값 = RepositoryReadingSource)', () {
    setUp(() => Repositories.useFakes(signedInUserId: FakeData.myUserId));

    testWidgets('화면을 열어 둔 채로 뱃지를 받으면 바로 늘어난다', (tester) async {
      final before = (await Repositories.user.fetchProfile(FakeData.myUserId))
          .badgeIds
          .length;

      await tester.pumpWidget(
        MaterialApp(home: ProfileScreen(userId: FakeData.myUserId)),
      );
      await pumpUntilLoaded(tester);
      expect(find.text(AppStrings.profileBadgeCount(before)), findsOneWidget);

      // S06 저장 = 뱃지 하나. 화면은 그대로 열려 있다.
      await Repositories.reading.saveInterpretation(
        FakeData.myUserId,
        const Reading(poemId: 'bomgoyangi', interpretation: '봄은 고양이로다 내 해석'),
        summary: null,
      );
      await tester.pumpAndSettle();

      expect(
        find.text(AppStrings.profileBadgeCount(before + 1)),
        findsOneWidget,
      );
      expect(find.byType(BadgeImage), findsNWidgets(before + 1));
    });

    testWidgets('화면을 열어 둔 채로 누적일수가 오르면 바로 바뀐다', (tester) async {
      final before = (await Repositories.user.fetchProfile(FakeData.myUserId))
          .totalReadingDays;

      await tester.pumpWidget(
        MaterialApp(home: ProfileScreen(userId: FakeData.myUserId)),
      );
      await pumpUntilLoaded(tester);
      expect(find.text(AppStrings.homeTotalDays(before)), findsOneWidget);

      // S04에서 시를 읽으면 부르는 그 함수. 오늘 처음이면 하루가 오른다.
      await Repositories.user.countReadingDay(FakeData.myUserId);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.homeTotalDays(before + 1)), findsOneWidget);
      expect(find.text(AppStrings.homeTotalDays(before)), findsNothing);
    });
  });

  group('구독 자체', () {
    final profile = UserProfile(
      userId: 'user_star_1',
      nickname: '별하나',
      totalReadingDays: 3,
      lastCountedDate: DateTime(2026, 11, 17),
      badgeIds: const ['seosi'],
    );

    testWidgets('watchProfile을 구독한다', (tester) async {
      final source = StubReadingSource(profiles: {profile.userId: profile});

      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(userId: profile.userId, source: source),
        ),
      );
      await pumpUntilLoaded(tester);

      expect(source.calls, contains('watchProfile:user_star_1'));
      expect(find.text(AppStrings.profileBadgeCount(1)), findsOneWidget);
    });

    testWidgets('갱신이 오면 뱃지가 늘어난다', (tester) async {
      final source = StubReadingSource(profiles: {profile.userId: profile});

      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(userId: profile.userId, source: source),
        ),
      );
      await pumpUntilLoaded(tester);

      source.pushProfile(
        profile.copyWith(badgeIds: const ['seosi', 'jindallae']),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.profileBadgeCount(2)), findsOneWidget);
      expect(find.byType(BadgeImage), findsNWidgets(2));
    });

    testWidgets('다른 사람의 갱신은 무시한다', (tester) async {
      final source = StubReadingSource(profiles: {profile.userId: profile});

      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(userId: profile.userId, source: source),
        ),
      );
      await pumpUntilLoaded(tester);

      source.pushProfile(UserProfile(
        userId: 'someone_else',
        nickname: '남',
        totalReadingDays: 99,
        lastCountedDate: DateTime(2026, 11, 17),
        badgeIds: const ['seosi', 'jindallae', 'bomgoyangi'],
      ));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.profileBadgeCount(1)), findsOneWidget);
    });

    testWidgets('뱃지 제목을 뱃지마다 다시 읽지 않는다 (N+1 방지)', (tester) async {
      final source = StubReadingSource(
        profiles: {
          profile.userId: profile.copyWith(
            badgeIds: const ['seosi', 'jindallae', 'bomgoyangi'],
          ),
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(userId: profile.userId, source: source),
        ),
      );
      await pumpUntilLoaded(tester);

      expect(source.calls.where((c) => c.startsWith('poemById:')), isEmpty);
    });
  });

  group('프로필이 없으면', () {
    testWidgets('영원히 로딩에 머물지 않고 안내를 보여 준다', (tester) async {
      // watchProfile은 없는 프로필에 아무것도 내보내지 않는다. 화면이
      // profileById로 먼저 읽지 않으면 스피너가 끝나지 않는다.
      final source = StubReadingSource(throwOnRead: true);

      await tester.pumpWidget(
        MaterialApp(home: ProfileScreen(userId: 'nobody', source: source)),
      );
      await pumpUntilLoaded(tester);

      expect(find.byType(UnavailableNotice), findsOneWidget);
    });
  });
}
