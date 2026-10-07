import 'package:flutter_test/flutter_test.dart';
import 'package:yeobaek/main.dart';

void main() {
  testWidgets('Part D screens hub smoke test', (WidgetTester tester) async {
    // YeobaekApp 렌더링
    await tester.pumpWidget(const YeobaekApp());

    // 초기 타이틀 확인
    expect(find.text('여백 — 담당 D 화면 테스트'), findsOneWidget);
    expect(find.text('S07. 전문가 해석 대조'), findsOneWidget);
    expect(find.text('S08. 모두의 대화 목록'), findsOneWidget);
    expect(find.text('S12. 내 프로필 (내 선반)'), findsOneWidget);
  });
}
