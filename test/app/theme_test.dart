// 공용 테마 (A) — 화면이 스타일을 직접 쓰지 않아도 테마가 정한 글자로 나오는지
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yeobaek/app/theme.dart';

void main() {
  testWidgets('확인 창 제목 · 본문은 테마의 글자 스타일을 쓴다', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildAppTheme(),
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => const AlertDialog(
              title: Text('제목'),
              content: Text('본문'),
            ),
          ),
          child: const Text('열기'),
        ),
      ),
    ));
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();

    TextStyle styleOf(String text) => tester
        .widget<RichText>(
            find.descendant(of: find.text(text), matching: find.byType(RichText)))
        .text
        .style!;
    final title = styleOf('제목');
    final content = styleOf('본문');

    expect(title.fontSize, AppText.screenTitle.fontSize);
    expect(title.fontWeight, AppText.screenTitle.fontWeight);
    expect(title.color, AppText.screenTitle.color);
    expect(content.fontSize, AppText.body.fontSize);
    expect(content.color, AppText.body.color);
  });
}
