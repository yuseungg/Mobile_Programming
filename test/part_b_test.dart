// B의 part-b 흐름 테스트를 이름만 맞춰 옮겼다 (docs/여백-이름대조표.md).
// 1단계 흐름: S01 → S03 → S04 행 표시 → S05 → S06 → S07
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yeobaek/features/compare/comparison_screen.dart';
import 'package:yeobaek/main.dart';

void main() {
  testWidgets('B 흐름: S03 → S04 행 표시 → S05 → S06 → S07', (tester) async {
    await tester.pumpWidget(const YeobaekApp());
    await tester.pumpAndSettle();

    // S01 → S03
    await tester.ensureVisible(find.text('로그인'));
    await tester.tap(find.text('로그인'));
    await tester.pumpAndSettle();

    // S03 → S04
    await tester.tap(find.text('혼자 읽기 시작'));
    await tester.pumpAndSettle();

    // 멈춘 사람 수는 그 행을 눌러야 보임
    expect(find.text('12명'), findsNothing);
    await tester.tap(find.text('한 점 부끄럼이 없기를,'));
    await tester.pump();
    expect(find.text('12명'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byType(TextField),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.byType(TextField), '부끄럼');
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('이 낱말로 대화 시작'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('이 낱말로 대화 시작'));
    await tester.pumpAndSettle();

    // S05 → S06
    await tester.tap(find.text('내 해석 정리하기'));
    await tester.pumpAndSettle();

    // S06 → S07 (저장 버튼은 화면 아래 고정이라 스크롤 불필요)
    await tester.tap(find.text('저장하기'));
    await tester.pumpAndSettle();
    expect(find.byType(ComparisonScreen), findsOneWidget);
  });
}
