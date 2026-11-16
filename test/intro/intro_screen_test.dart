// 주인: D — S13 안내 화면
// 기준: 로그인 다음 · 홈 앞, 두세 번 스크롤, 맨 밑 버튼, 30초 뒤 자동 전환,
//       마음에 남은 줄 · 지금까지, 위쪽 건너뛰기
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yeobaek/app/router.dart';
import 'package:yeobaek/app/strings.dart';
import 'package:yeobaek/app/tab_shell.dart';
import 'package:yeobaek/data/fakes/fake_data.dart';
import 'package:yeobaek/data/models/reading.dart';
import 'package:yeobaek/data/models/user_profile.dart';
import 'package:yeobaek/data/repositories.dart';
import 'package:yeobaek/features/intro/intro_screen.dart';
import 'package:yeobaek/ports/reading_source.dart';
import 'package:yeobaek/shared/widgets/app_button.dart';

import '../support/stub_reading_source.dart';

void main() {
  setUp(() => Repositories.useFakes(signedInUserId: FakeData.myUserId));

  /// 실제 라우터로 띄운다 — 홈으로 가는 길이 라우터에 없으면 여기서 깨진다.
  Widget app() => MaterialApp(
        onGenerateRoute: AppRouter.onGenerateRoute,
        initialRoute: AppRoutes.intro,
      );

  Widget withSource(ReadingSource source) => MaterialApp(
        onGenerateRoute: AppRouter.onGenerateRoute,
        home: IntroScreen(source: source),
      );

  final button = find.text(AppStrings.introStart);

  UserProfile profile({int days = 0, List<String> badges = const []}) =>
      UserProfile(
        userId: FakeData.myUserId,
        nickname: '아무개',
        totalReadingDays: days,
        lastCountedDate: DateTime(2026, 11, 13),
        badgeIds: badges,
      );

  group('넘어가기', () {
    testWidgets('기다리면 30초에 홈으로 넘어간다', (tester) async {
      await tester.pumpWidget(app());
      expect(find.byType(IntroScreen), findsOneWidget);

      // 29초까지는 그대로 있어야 한다
      await tester.pump(const Duration(seconds: 29));
      expect(find.byType(TabShell), findsNothing);

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.byType(TabShell), findsOneWidget);
      expect(find.byType(IntroScreen), findsNothing);
    });

    testWidgets('버튼을 누르면 기다리지 않고 넘어간다', (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(button, 400);
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(find.byType(TabShell), findsOneWidget);
    });

    testWidgets('버튼으로 넘어간 뒤 타이머가 홈을 한 번 더 밀지 않는다',
        (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(button, 400);
      await tester.tap(button);
      await tester.pumpAndSettle();

      // 타이머가 울릴 시각을 지나 보낸다. 살아 있었다면 홈이 또 밀려든다.
      await tester.pump(const Duration(seconds: 40));
      await tester.pumpAndSettle();

      expect(find.byType(TabShell), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('버튼은 두세 번 스크롤한 끝에 있다', (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable);
      final viewport = tester.getSize(scrollable).height;
      final position = tester.state<ScrollableState>(scrollable).position;

      final screens = position.maxScrollExtent / viewport;
      expect(screens, inInclusiveRange(2, 3),
          reason: '스크롤 분량이 두세 화면이어야 한다 (지금 ${screens.toStringAsFixed(1)})');

      expect(tester.getTopLeft(button).dy, greaterThan(viewport));
      await tester.scrollUntilVisible(button, 400);
      expect(tester.getTopLeft(button).dy, lessThan(viewport));
    });
  });

  group('마음에 남은 줄', () {
    testWidgets('고른 줄이 시 제목과 함께 나온다', (tester) async {
      final source = StubReadingSource(
        readings: {
          'seosi': const Reading(
            poemId: 'seosi',
            markedLines: [2, 10],
            impressiveLine: 10,
            isSaved: true,
          ),
          'jindallae': const Reading(
            poemId: 'jindallae',
            markedLines: [3],
            impressiveLine: 3,
            isSaved: true,
          ),
        },
        profiles: {FakeData.myUserId: profile()},
      );

      await tester.pumpWidget(withSource(source));
      await tester.pumpAndSettle();

      expect(find.text('오늘 밤에도 별이 바람에 스치운다.'), findsOneWidget);
      expect(find.text('말없이 고이 보내 드리우리다'), findsOneWidget);
      expect(find.text('서시'), findsOneWidget);
      expect(find.text('진달래꽃'), findsOneWidget);
      expect(find.text(AppStrings.introLinesEmpty), findsNothing);
    });

    testWidgets('아직 하나도 안 골랐으면 안내 한 줄만', (tester) async {
      final source = StubReadingSource(
        readings: {
          'seosi': const Reading(poemId: 'seosi', markedLines: [2]),
        },
        profiles: {FakeData.myUserId: profile()},
      );

      await tester.pumpWidget(withSource(source));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.introLinesEmpty), findsOneWidget);
    });

    testWidgets('행 번호가 시 밖이면 그 줄만 건너뛴다', (tester) async {
      final source = StubReadingSource(
        readings: {
          'seosi': const Reading(
            poemId: 'seosi',
            markedLines: [999],
            impressiveLine: 999, // 서시는 10행까지다
            isSaved: true,
          ),
          'jindallae': const Reading(
            poemId: 'jindallae',
            markedLines: [3],
            impressiveLine: 3,
            isSaved: true,
          ),
        },
        profiles: {FakeData.myUserId: profile()},
      );

      await tester.pumpWidget(withSource(source));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('말없이 고이 보내 드리우리다'), findsOneWidget);
      expect(find.text('서시'), findsNothing);
    });
  });

  group('지금까지', () {
    testWidgets('읽은 날 · 나눈 글 · 받은 뱃지를 센다', (tester) async {
      final source = StubReadingSource(
        readings: {
          // 저장하고 공개한 것만 「나눈 글」이다
          'seosi': const Reading(poemId: 'seosi', isSaved: true, isPublic: true),
          'jindallae': const Reading(
            poemId: 'jindallae',
            isSaved: true,
            isPublic: false,
          ),
          'bomgoyangi': const Reading(poemId: 'bomgoyangi', isPublic: true),
        },
        profiles: {
          FakeData.myUserId: profile(days: 12, badges: ['seosi', 'jindallae']),
        },
      );

      await tester.pumpWidget(withSource(source));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text(AppStrings.introDays(12)), 400);
      expect(find.text(AppStrings.introDays(12)), findsOneWidget);
      expect(find.text(AppStrings.introShared(1)), findsOneWidget);
      expect(find.text(AppStrings.introBadges(2)), findsOneWidget);
    });

    testWidgets('아무것도 없으면 0으로 나온다', (tester) async {
      final source = StubReadingSource(
        profiles: {FakeData.myUserId: profile()},
      );

      await tester.pumpWidget(withSource(source));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text(AppStrings.introDays(0)), 400);
      expect(find.text(AppStrings.introShared(0)), findsOneWidget);
      expect(find.text(AppStrings.introBadges(0)), findsOneWidget);
    });
  });

  group('건너뛰기 · 들어오는 길 (PR #27 리뷰 — 승민)', () {
    final skip = find.text(AppStrings.introSkip);

    testWidgets('건너뛰기는 스크롤하지 않아도 첫 화면에 보인다', (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      final viewport = tester.getSize(find.byType(Scrollable)).height;
      expect(tester.getTopLeft(skip).dy, lessThan(viewport));
    });

    testWidgets('건너뛰기를 누르면 바로 홈으로 간다', (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      await tester.tap(skip);
      await tester.pumpAndSettle();

      expect(find.byType(TabShell), findsOneWidget);
      expect(find.byType(IntroScreen), findsNothing);

      // 타이머가 울릴 시각을 지나 보낸다 — 홈이 한 번 더 밀려들면 안 된다
      await tester.pump(const Duration(seconds: 40));
      await tester.pumpAndSettle();
      expect(find.byType(TabShell), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('맨 아래까지 내려가도 건너뛰기는 그 자리에 있다', (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      final before = tester.getTopLeft(skip);
      await tester.scrollUntilVisible(button, 400);

      expect(skip, findsOneWidget);
      expect(tester.getTopLeft(skip), before);
    });

    testWidgets('가입 직후에는 S13을 건너뛰고 바로 홈으로 간다', (tester) async {
      await tester.pumpWidget(MaterialApp(
        onGenerateRoute: AppRouter.onGenerateRoute,
        initialRoute: AppRoutes.signUp,
      ));
      await tester.pumpAndSettle();

      final signUp = find.byType(AppPrimaryButton);
      await tester.ensureVisible(signUp);
      await tester.tap(signUp);
      await tester.pumpAndSettle();

      expect(find.byType(IntroScreen), findsNothing);
      expect(find.byType(TabShell), findsOneWidget);
    });
  });
}
