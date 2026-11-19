// C — 앱을 켰을 때 관문(AuthGate)이 어디로 보내는지 (로그인 분기 ④)
import 'package:flutter_test/flutter_test.dart';
import 'package:yeobaek/app/tab_shell.dart';
import 'package:yeobaek/data/fakes/fake_data.dart';
import 'package:yeobaek/data/repositories.dart';
import 'package:yeobaek/features/auth/sign_in_screen.dart';
import 'package:yeobaek/features/auth/sign_up_screen.dart';
import 'package:yeobaek/features/intro/intro_screen.dart';
import 'package:yeobaek/main.dart';

void main() {
  testWidgets('로그인 안 했으면 로그인 화면(S01)부터 보인다', (tester) async {
    Repositories.useFakes(signedOut: true);
    await tester.pumpWidget(const YeobaekApp());
    await tester.pumpAndSettle();

    expect(find.byType(SignInScreen), findsOneWidget);
    expect(find.text('여백'), findsOneWidget);
    expect(find.text('구글로 시작하기'), findsOneWidget);
  });

  testWidgets('로그인돼 있으면 S13 없이 바로 홈으로 간다', (tester) async {
    Repositories.useFakes(signedInUserId: FakeData.myUserId);
    await tester.pumpWidget(const YeobaekApp());
    await tester.pumpAndSettle();

    expect(find.byType(TabShell), findsOneWidget);
    expect(find.byType(IntroScreen), findsNothing);
    expect(find.byType(SignInScreen), findsNothing);
  });

  testWidgets('로그인됐는데 프로필이 없으면 닉네임 정하기로 간다', (tester) async {
    Repositories.useFakes(signedInUserId: 'google_newcomer');
    await tester.pumpWidget(const YeobaekApp());
    await tester.pumpAndSettle();

    expect(find.byType(SignUpScreen), findsOneWidget);
    expect(find.byType(TabShell), findsNothing);
  });

  test('로그인 안 한 상태에서 내 id를 꺼내면 막힌다', () {
    Repositories.useFakes(signedOut: true);
    expect(() => Repositories.userId, throwsStateError);

    Repositories.useFakes();
    expect(Repositories.userId, FakeData.myUserId);
  });
}
