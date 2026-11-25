// KR / EN 전환 — 주인: A
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeobaek/app/language.dart';
import 'package:yeobaek/shared/widgets/language_toggle.dart';
import 'package:yeobaek/app/router.dart';
import 'package:yeobaek/app/strings.dart';
import 'package:yeobaek/app/theme.dart';
import 'package:yeobaek/data/repositories.dart';
import 'package:yeobaek/features/home/home_screen.dart';
import 'package:yeobaek/features/intro/intro_screen.dart';
import 'package:yeobaek/features/settings/settings_edit_screen.dart';
import 'package:yeobaek/main.dart';

Widget _app(Widget first) => MaterialApp(
      theme: buildAppTheme(),
      onGenerateRoute: AppRouter.onGenerateRoute,
      onGenerateInitialRoutes: (_) =>
          [MaterialPageRoute<void>(builder: (_) => first)],
    );

/// 토글은 화면 오른쪽 위에 있어야 한다 — 오른쪽 끝에서 여백만큼, 위쪽 AppBar 높이 안.
void _expectTopRight(WidgetTester tester) {
  final toggle = find.byType(LanguageToggle);
  expect(toggle, findsOneWidget);
  final rect = tester.getRect(toggle);
  final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
  expect(rect.right, closeTo(screen.width, 0.5));
  expect(rect.top, lessThan(kToolbarHeight));
  expect(rect.bottom, lessThanOrEqualTo(kToolbarHeight + 0.5));
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    appLanguage.value = AppLanguage.ko;
  });
  tearDown(() => appLanguage.value = AppLanguage.ko);

  group('문구', () {
    test('고른 언어에 따라 바뀐다', () {
      expect(AppStrings.signInButton, '로그인');
      expect(AppStrings.lineList([2, 6]), '2행, 6행');
      appLanguage.value = AppLanguage.en;
      expect(AppStrings.signInButton, 'Sign in');
      expect(AppStrings.lineList([6]), 'Line 6');
      expect(AppStrings.lineList([2, 6]), 'Lines 2, 6');
      expect(AppStrings.comparisonRelationDifferentLines([2, 6]),
          'This interpretation centers on lines 2, 6');
      expect(AppStrings.monthDay(DateTime(2026, 11, 23)), 'Nov 23');
    });

    test('영어 문구에도 「쓰지 않는 말」이 없다', () {
      final source = File('lib/app/strings.dart').readAsStringSync();
      final code = source
          .split('\n')
          .where((line) => !line.trimLeft().startsWith('//'))
          .join('\n')
          .toLowerCase();
      for (final word in [
        '정답', '해설', '올바른', //
        'answer', 'correct', 'explanation', 'commentary',
      ]) {
        expect(code.contains(word), isFalse, reason: word);
      }
    });
  });

  group('기기에 남기기', () {
    test('처음 켜면 영어 — 교수님 공지', () async {
      expect(defaultAppLanguage, AppLanguage.en);
      await loadAppLanguage(); // 남긴 값 없음 = 처음 설치
      expect(appLanguage.value, AppLanguage.en);
    });

    test('고른 언어를 다음 실행에서 다시 읽는다', () async {
      appLanguage.value = AppLanguage.en;
      await changeAppLanguage(AppLanguage.ko);
      appLanguage.value = AppLanguage.en; // 앱을 껐다 켠 셈
      await loadAppLanguage();
      expect(appLanguage.value, AppLanguage.ko);
    });

    test('모르는 값이면 영어', () async {
      SharedPreferences.setMockInitialValues({'appLanguage': 'fr'});
      await loadAppLanguage();
      expect(appLanguage.value, AppLanguage.en);
    });
  });

  group('앱 전체', () {
    setUp(() => Repositories.useFakes(signedOut: true));

    testWidgets('S01에서 EN을 누르면 바로 영어 — 입력하던 글은 남는다', (tester) async {
      await tester.pumpWidget(const YeobaekApp());
      await tester.pumpAndSettle();
      _expectTopRight(tester);
      expect(find.text('로그인'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'reader@gmail.com');
      await tester.tap(find.text(AppStrings.languageEnglish));
      await tester.pumpAndSettle();

      expect(find.text('Sign in'), findsOneWidget);
      expect(find.text('로그인'), findsNothing);
      expect(find.text('reader@gmail.com'), findsOneWidget);

      await tester.tap(find.text(AppStrings.languageKorean));
      await tester.pumpAndSettle();
      expect(find.text('로그인'), findsOneWidget);
    });

    testWidgets('처음 설치하고 켜면 S01부터 영어', (tester) async {
      await loadAppLanguage(); // main()이 runApp 전에 부르는 것과 같다
      await tester.pumpWidget(const YeobaekApp());
      await tester.pumpAndSettle();
      expect(find.text('Sign in'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
    });

    testWidgets('뒤에 쌓인 화면도 같이 바뀐다', (tester) async {
      await tester.pumpWidget(const YeobaekApp());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('가입하기'));
      await tester.tap(find.text('가입하기'));
      await tester.pumpAndSettle();
      _expectTopRight(tester); // S02
      await tester.tap(find.text(AppStrings.languageEnglish));
      await tester.pumpAndSettle();
      expect(find.text('To keep what you read'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text("Don't have an account?"), findsOneWidget); // S01
    });
  });

  group('기존 버튼은 그대로, 토글은 그 오른쪽', () {
    setUp(() => Repositories.useFakes());

    testWidgets('S03 홈 — 프로필 버튼 오른쪽', (tester) async {
      await tester.pumpWidget(_app(const HomeScreen()));
      await tester.pumpAndSettle();
      _expectTopRight(tester);
      final profile = tester.getRect(find.byTooltip('내 프로필'));
      expect(profile.right, lessThanOrEqualTo(
          tester.getRect(find.byType(LanguageToggle)).left));
    });

    testWidgets('S11 설정 바꾸기 — 저장 버튼 오른쪽', (tester) async {
      await tester.pumpWidget(_app(const SettingsEditScreen()));
      await tester.pumpAndSettle();
      _expectTopRight(tester);
      final save = tester.getRect(find.widgetWithText(TextButton, '저장'));
      expect(save.right,
          lessThanOrEqualTo(tester.getRect(find.byType(LanguageToggle)).left));
    });

    testWidgets('S13 안내 — 건너뛰기 오른쪽', (tester) async {
      await tester.pumpWidget(_app(const IntroScreen()));
      await tester.pump();
      _expectTopRight(tester);
      final skip = tester.getRect(find.widgetWithText(TextButton, '건너뛰기'));
      expect(skip.right,
          lessThanOrEqualTo(tester.getRect(find.byType(LanguageToggle)).left));
    });
  });
}
