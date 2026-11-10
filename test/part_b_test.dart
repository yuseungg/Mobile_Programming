// B의 part-b 흐름 테스트를 이름만 맞춰 옮겼다 (docs/여백-이름대조표.md).
// 1단계 흐름: S01 → S03 → S04 행 표시 → S05 → S06 → S07
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yeobaek/features/compare/comparison_screen.dart';
import 'package:yeobaek/features/reading/reading_screen.dart';
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


  //AI
  // 크롬에서 한글 계속 치면 조합 중이라 20자 제한 뚫리던 버그
  testWidgets('첫 낱말은 한글 조합 중에도 20자를 넘지 않는다', (tester) async {
    // 맥은 웹이랑 기본 방식이 같아서 맥으로 흉내
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS; //AI
    await tester.pumpWidget(
      const MaterialApp(home: ReadingScreen(poemId: 'seosi')),
    );
    final field = find.byType(TextField);
    await tester.scrollUntilVisible(
      field,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.showKeyboard(field);



    // 마지막 글자 계속 조합 중인 채로 22자까지 입력
    for (final text in ['가' * 20, '${'가' * 20}나', '${'가' * 21}다']) { //AI
      tester.testTextInput.updateEditingValue(
        TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
            composing: TextRange(start: text.length - 1, end: text.length), //AI
        ),
      );
      await tester.pump();
    }

    expect(tester.widget<TextField>(field).controller!.text.length,  20);
    debugDefaultTargetPlatformOverride = null;
  });
}
