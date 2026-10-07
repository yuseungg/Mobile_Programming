import 'package:flutter_test/flutter_test.dart';

import 'package:yeobaek/main.dart';

void main() {
  testWidgets('앱을 켜면 로그인 화면(S01)부터 보인다', (tester) async {
    await tester.pumpWidget(const YeobaekApp());
    await tester.pumpAndSettle();

    expect(find.text('여백'), findsOneWidget);
    expect(find.text('구글로 시작하기'), findsOneWidget);
  });
}
