// 주인: D — S13 안내 화면
// 기준: 로그인 다음 · 홈 앞, 두세 번 스크롤, 맨 밑 버튼, 15초 뒤 자동 전환
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yeobaek/app/router.dart';
import 'package:yeobaek/app/strings.dart';
import 'package:yeobaek/app/tab_shell.dart';
import 'package:yeobaek/data/repositories.dart';
import 'package:yeobaek/features/intro/intro_screen.dart';

void main() {
  setUp(() => Repositories.useFakes(signedInUserId: 'me'));

  /// 실제 라우터로 띄운다 — 홈으로 가는 길이 라우터에 없으면 여기서 깨진다.
  Widget app() => MaterialApp(
        onGenerateRoute: AppRouter.onGenerateRoute,
        initialRoute: AppRoutes.intro,
      );

  final button = find.text(AppStrings.introStart);

  group('S13 안내', () {
    testWidgets('기다리면 15초에 홈으로 넘어간다', (tester) async {
      await tester.pumpWidget(app());
      expect(find.byType(IntroScreen), findsOneWidget);

      // 14초까지는 그대로 있어야 한다
      await tester.pump(const Duration(seconds: 14));
      expect(find.byType(TabShell), findsNothing);

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.byType(TabShell), findsOneWidget);
      expect(find.byType(IntroScreen), findsNothing);
    });

    testWidgets('버튼을 누르면 기다리지 않고 넘어간다', (tester) async {
      await tester.pumpWidget(app());

      await tester.scrollUntilVisible(button, 400);
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(find.byType(TabShell), findsOneWidget);
      expect(find.byType(IntroScreen), findsNothing);
    });

    testWidgets('버튼으로 넘어간 뒤 타이머가 홈을 한 번 더 밀지 않는다',
        (tester) async {
      await tester.pumpWidget(app());

      await tester.scrollUntilVisible(button, 400);
      await tester.tap(button);
      await tester.pumpAndSettle();

      // 타이머가 울릴 시각을 지나 보낸다. 살아 있었다면 홈이 또 밀려든다.
      await tester.pump(const Duration(seconds: 20));
      await tester.pumpAndSettle();

      expect(find.byType(TabShell), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('버튼은 두세 번 스크롤한 끝에 있다', (tester) async {
      await tester.pumpWidget(app());

      final scrollable = find.byType(Scrollable);
      final viewport = tester.getSize(scrollable).height;
      final position = tester.state<ScrollableState>(scrollable).position;

      // 스크롤로 내려가야 하는 거리 ÷ 한 번에 넘기는 거리
      final screens = position.maxScrollExtent / viewport;
      expect(screens, inInclusiveRange(2, 3),
          reason: '스크롤 분량이 두세 화면이어야 한다 (지금 ${screens.toStringAsFixed(1)})');

      // 그리고 버튼은 처음에 화면 밖, 끝까지 내리면 안에 있다
      expect(tester.getTopLeft(button).dy, greaterThan(viewport));
      await tester.scrollUntilVisible(button, 400);
      expect(tester.getTopLeft(button).dy, lessThan(viewport));
    });

    testWidgets('본문 문구는 아직 비어 있다 — 앱 이름만 보인다', (tester) async {
      await tester.pumpWidget(app());
      expect(find.text(AppStrings.appName), findsOneWidget);
      expect(find.text(AppStrings.appSubtitle), findsOneWidget);
      // 타이머를 남겨 두면 테스트가 「pending timer」로 깨진다
      await tester.pump(const Duration(seconds: 15));
      await tester.pumpAndSettle();
    });
  });
}
