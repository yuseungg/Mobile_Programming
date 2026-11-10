// B의 part-b 흐름 테스트를 이름만 맞춰 옮겼다 (docs/여백-이름대조표.md).
// 1단계 흐름: S01 → S03 → S04 행 표시 → S05 → S06 → S07
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yeobaek/data/models/user_profile.dart';
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
    expect(find.text('13명'), findsOneWidget); // 다른 사람 12 + 나

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
    await tester.pumpWidget(const MaterialApp(home: ReadingScreen(poemId: 'seosi')));
    Finder field = find.byType(TextField);
    await tester.scrollUntilVisible(field, 200,
        scrollable: find.byType(Scrollable).first);
    await tester.showKeyboard(field);



    //마지막 글자 계속 조합 중인 채로 22자까지 입력
    List<String> inputs = [];
    inputs.add('가' * 20);
    inputs.add('${'가' * 20}나'); //AI
    inputs.add('${'가' * 21}다');

    for (String text in inputs) {
      TextEditingValue value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
            composing: TextRange(start: text.length - 1, end: text.length)); //AI
      tester.testTextInput.updateEditingValue(value);
      await tester.pump();
    }

    TextField textField = tester.widget<TextField>(field);
    expect(textField.controller!.text.length,  20);
      debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('읽던 시 다시 열면 멈춘 행이랑 첫 낱말 불러옴', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ReadingScreen(poemId: 'seosi')));

    expect(find.text('8명'), findsOneWidget); // 저장돼 있던 6행
    await tester.scrollUntilVisible(find.byType(TextField), 200, scrollable: find.byType(Scrollable).first);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, '부끄러움');
  });


  //AI
  test('누적일수는 날짜 바뀔 때만 하루씩 늘어남', () {
    final me = UserProfile(userId: 'me', nickname: 'x', totalReadingDays: 12,
        lastCountedDate: DateTime(2026, 11, 10), badgeIds: const []);

    expect(countReadingDay(me, DateTime(2026, 11, 10, 23, 59)).totalReadingDays, 12);
    final next = countReadingDay(me, DateTime(2026, 11, 11, 0, 1));
    expect(next.totalReadingDays, 13);
    // 며칠 건너뛰어도 +1만 (연속 아님)
    expect(countReadingDay(next, DateTime(2026, 11, 20)).totalReadingDays,14);
  });
}
