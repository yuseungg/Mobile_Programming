// S01 로그인 · S02 가입 — 주인: C
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yeobaek/app/language.dart';
import 'package:yeobaek/app/router.dart';
import 'package:yeobaek/app/strings.dart';
import 'package:yeobaek/app/tab_shell.dart';
import 'package:yeobaek/app/theme.dart';
import 'package:yeobaek/data/fakes/fake_auth_repository.dart';
import 'package:yeobaek/data/nickname_words.dart';
import 'package:yeobaek/data/repositories.dart';
import 'package:yeobaek/features/auth/auth_input_rules.dart';
import 'package:yeobaek/features/auth/sign_in_screen.dart';
import 'package:yeobaek/features/auth/sign_up_screen.dart';
import 'package:yeobaek/features/intro/intro_screen.dart';

// home:을 쓰면 '/'(S03 홈)로 가는 이동이 home 위젯으로 되돌아온다 (MaterialApp 규칙).
// 그래서 첫 화면은 onGenerateInitialRoutes로 띄우고, '/'는 실제 라우터가 받게 한다.
Widget _app(Widget first) => MaterialApp(
      theme: buildAppTheme(),
      onGenerateRoute: AppRouter.onGenerateRoute,
      onGenerateInitialRoutes: (_) => [MaterialPageRoute<void>(builder: (_) => first)],
    );

Finder _field(int index) => find.byType(TextField).at(index);

FilledButton _primaryButton(WidgetTester tester, String label) =>
    tester.widget<FilledButton>(find.widgetWithText(FilledButton, label));

Future<void> _tapPrimary(WidgetTester tester, String label) async {
  final button = find.widgetWithText(FilledButton, label);
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => Repositories.useFakes(signedOut: true));

  group('입력 규칙', () {
    test('gmail.com 주소만', () {
      expect(isValidGmail('reader@gmail.com'), isTrue);
      expect(isValidGmail('Reader@Gmail.com'), isTrue);
      expect(isValidGmail('reader@cau.ac.kr'), isFalse);
      expect(isValidGmail('reader@gmail.com.kr'), isFalse);
      expect(isValidGmail('@gmail.com'), isFalse);
    });

    test('비밀번호는 6자 이상 · 영문 소문자와 숫자만', () {
      expect(isValidPassword('abc123'), isTrue);
      expect(isValidPassword('abc12'), isFalse);
      expect(isValidPassword('Abc123'), isFalse);
      expect(isValidPassword('abc 123'), isFalse);
    });
  });

  group('S01 로그인', () {
    testWidgets('비밀번호 칸은 대문자 · 한글 · 특수기호 · 공백이 입력되지 않는다', (tester) async {
      await tester.pumpWidget(_app(const SignInScreen()));
      await tester.enterText(_field(1), 'AbC가 1!x');
      expect(tester.widget<TextField>(_field(1)).controller!.text, 'b1x');
    });

    testWidgets('이메일 칸은 공백이 입력되지 않는다', (tester) async {
      await tester.pumpWidget(_app(const SignInScreen()));
      await tester.enterText(_field(0), 'demo @gmail.com');
      expect(tester.widget<TextField>(_field(0)).controller!.text,
          'demo@gmail.com');
    });

    testWidgets('gmail 주소가 아니면 로그인 버튼이 눌리지 않는다', (tester) async {
      await tester.pumpWidget(_app(const SignInScreen()));
      await tester.enterText(_field(0), 'demo@naver.com');
      await tester.enterText(_field(1), 'yeobaek1');
      await tester.pump();
      expect(_primaryButton(tester, AppStrings.signInButton).onPressed, isNull);
    });

    testWidgets('데모 계정으로 로그인하면 S13 안내로 간다', (tester) async {
      await tester.pumpWidget(_app(const SignInScreen()));
      await tester.enterText(_field(0), FakeAuthRepository.demoEmail);
      await tester.enterText(_field(1), FakeAuthRepository.demoPassword);
      await tester.pump();
      await _tapPrimary(tester, AppStrings.signInButton);

      expect(find.byType(IntroScreen), findsOneWidget);
      expect(Repositories.auth.currentUserId, isNotNull);
    });

    testWidgets('구글로 시작하기 — 프로필이 있는 계정이면 S13 안내로 간다', (tester) async {
      // 가짜 구글 로그인은 프로필이 있는 데모 사용자로 들어온다.
      // 프로필이 없는 경우(닉네임 정하기)는 아래 「S02 닉네임만 정하기」에서 본다.
      await tester.pumpWidget(_app(const SignInScreen()));
      final googleButton = find.text(AppStrings.signInGoogleButton);
      await tester.ensureVisible(googleButton);
      await tester.tap(googleButton);
      await tester.pumpAndSettle();

      expect(find.byType(IntroScreen), findsOneWidget);
    });

    testWidgets('비밀번호가 틀리면 안내가 뜨고 그대로 남는다', (tester) async {
      await tester.pumpWidget(_app(const SignInScreen()));
      await tester.enterText(_field(0), FakeAuthRepository.demoEmail);
      await tester.enterText(_field(1), 'wrong1');
      await tester.pump();
      await _tapPrimary(tester, AppStrings.signInButton);

      expect(find.text(AppStrings.authErrorInvalidCredentials), findsOneWidget);
      expect(find.byType(SignInScreen), findsOneWidget);
    });
  });

  group('S02 가입', () {
    Future<void> fillSignUp(
      WidgetTester tester, {
      String email = 'newreader@gmail.com',
      String password = 'abc123',
      String? confirm,
    }) async {
      await tester.enterText(_field(0), email);
      await tester.enterText(_field(1), password);
      await tester.enterText(_field(2), confirm ?? password);
      await tester.pump();
    }

    testWidgets('비밀번호 확인이 다르면 가입 버튼이 눌리지 않는다', (tester) async {
      await tester.pumpWidget(_app(const SignUpScreen()));
      await fillSignUp(tester, confirm: 'abc124');
      expect(find.text(AppStrings.signUpPasswordMismatch), findsOneWidget);
      expect(_primaryButton(tester, AppStrings.signUpButton).onPressed, isNull);
    });

    testWidgets('6자보다 짧으면 안내가 뜨고 가입 버튼이 눌리지 않는다', (tester) async {
      await tester.pumpWidget(_app(const SignUpScreen()));
      await fillSignUp(tester, password: 'abc12');
      expect(find.text(AppStrings.signUpPasswordTooShort(minPasswordLength)),
          findsOneWidget);
      expect(_primaryButton(tester, AppStrings.signUpButton).onPressed, isNull);
    });

    testWidgets('닉네임 새로고침을 누르면 다른 닉네임이 된다', (tester) async {
      await tester.pumpWidget(_app(const SignUpScreen()));
      final before = _nicknameShown(tester);
      await tester.tap(find.byTooltip(AppStrings.signUpNicknameRefresh));
      await tester.pump();
      expect(_nicknameShown(tester), isNot(before));
    });

    testWidgets('EN으로 열면 닉네임이 영어 단어로 지어진다', (tester) async {
      appLanguage.value = AppLanguage.en;
      addTearDown(() => appLanguage.value = AppLanguage.ko);
      await tester.pumpWidget(_app(const SignUpScreen()));
      final noun = _nicknameShown(tester).split(' ').last;
      expect(nicknameNounsEn, contains(noun));
    });

    testWidgets('가입하면 계정과 프로필이 생기고 홈으로 간다', (tester) async {
      await tester.pumpWidget(_app(const SignUpScreen()));
      final nickname = _nicknameShown(tester);
      await fillSignUp(tester);
      await _tapPrimary(tester, AppStrings.signUpButton);

      expect(find.byType(TabShell), findsOneWidget);
      final userId = Repositories.auth.currentUserId!;
      final profile = await Repositories.user.fetchProfile(userId);
      expect(profile.nickname, nickname);
    });

    testWidgets('이미 가입된 이메일이면 안내가 뜬다', (tester) async {
      await tester.pumpWidget(_app(const SignUpScreen()));
      await fillSignUp(tester, email: FakeAuthRepository.demoEmail);
      await _tapPrimary(tester, AppStrings.signUpButton);

      expect(find.text(AppStrings.authErrorEmailInUse), findsOneWidget);
      expect(find.byType(SignUpScreen), findsOneWidget);
    });
  });

  group('S02 닉네임만 정하기 (구글 첫 로그인)', () {
    setUp(() => Repositories.useFakes(signedInUserId: 'google_newcomer'));

    testWidgets('이메일 · 비밀번호 칸이 없고, 시작하면 프로필이 생긴다', (tester) async {
      await tester.pumpWidget(_app(const SignUpScreen(isNicknameOnly: true)));
      expect(find.byType(TextField), findsNothing);
      expect(await Repositories.user.hasProfile('google_newcomer'), isFalse);

      await _tapPrimary(tester, AppStrings.nicknameOnlyButton);

      expect(find.byType(TabShell), findsOneWidget);
      expect(await Repositories.user.hasProfile('google_newcomer'), isTrue);
    });

    testWidgets('다른 계정으로 로그인을 누르면 로그아웃하고 S01로 간다', (tester) async {
      await tester.pumpWidget(_app(const SignUpScreen(isNicknameOnly: true)));
      await tester.tap(find.text(AppStrings.nicknameOnlyOtherAccount));
      await tester.pumpAndSettle();

      expect(find.byType(SignInScreen), findsOneWidget);
      expect(Repositories.auth.currentUserId, isNull);
    });
  });
}

/// 닉네임 카드에 보이는 닉네임 — 화면에서 AppText.bodyStrong으로 쓰인 글은 닉네임뿐이다
String _nicknameShown(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .where((t) => t.style == AppText.bodyStrong)
    .single
    .data!;
