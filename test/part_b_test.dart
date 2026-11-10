import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yeobaek/data/fakes/fake_data.dart';
import 'package:yeobaek/features/compare/comparison_screen.dart';
import 'package:yeobaek/features/home/home_screen.dart';
import 'package:yeobaek/main.dart';

void main() {
  testWidgets('B 흐름: S03 → S04 행 표시 → S05 → S06 → S07', (tester) async {
    await tester.pumpWidget(const YeobaekApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('로그인'));
    await tester.tap(find.text('로그인'));
    await tester.pumpAndSettle();

    //오늘의 시는 날마다 바뀌어서 목록에서 서시 고름
    final seosiTile = find.widgetWithText(ListTile,'서시');
    await tester.scrollUntilVisible(seosiTile, 200, scrollable: find.byType(Scrollable).first);

    await tester.tap(seosiTile);
    await tester.pumpAndSettle();

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

    await tester.tap(find.text('내 해석 정리하기'));
    await tester.pumpAndSettle();

    // 저장 버튼은 하단 고정이라 스크롤 안 함
    await tester.tap(find.text('저장하기'));
    await tester.pumpAndSettle();
    expect(find.byType(ComparisonScreen), findsOneWidget);
  });



  //AI
  test('오늘의 시는 추가된 순서로 하루에 한 편씩 돌아간다', () {
    final poems = FakeData.poems;
    final day = DateTime(2026,11,10, 9);
    final first =todayPoem(poems, day);
    final i = poems.indexOf(first);
    expect(todayPoem(poems, DateTime(2026, 11, 10, 23, 59)), first);


    // 목록 끝 다음 날엔 처음 시로 돌아가는지 확인
    for (var d = 1; d <= poems.length; d++) {
      final next = todayPoem(poems, day.add(Duration(days: d)));
        expect(next, poems[(i + d) % poems.length]);
    }
  });
}
