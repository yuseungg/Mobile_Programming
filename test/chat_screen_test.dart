// S05 대화 화면 (A) — 키 없이 돌리면 가짜 에이전트가 답한다
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yeobaek/agent/prompts/fallback_questions.dart';
import 'package:yeobaek/app/strings.dart';
import 'package:yeobaek/app/theme.dart';
import 'package:yeobaek/features/chat/chat_screen.dart';

Widget _app(String poemId) =>
    MaterialApp(theme: buildAppTheme(), home: ChatScreen(poemId: poemId));

/// 가짜 에이전트는 0.7초 뒤에 답한다
Future<void> _waitForReply(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

Future<void> _send(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump();
  await tester.tap(find.text(AppStrings.chatSendButton));
  await tester.pump();
}

void main() {
  testWidgets('대화가 비어 있으면 첫 질문을 받는다', (tester) async {
    await tester.pumpWidget(_app('bomgoyangi'));
    await tester.pump(); // 첫 프레임 뒤에 요청을 보낸다
    expect(find.text(AppStrings.chatResponding), findsOneWidget);

    await _waitForReply(tester);
    expect(find.text(AppStrings.chatResponding), findsNothing);
    expect(find.text(openingFallbackQuestion('')), findsOneWidget);
  });

  testWidgets('보내면 답을 기다리는 동안 입력이 잠기고 중단 버튼이 나온다', (tester) async {
    await tester.pumpWidget(_app('seosi'));
    await tester.pumpAndSettle();

    await _send(tester, "'하늘을 보며'라는 구절 때문이에요");
    expect(find.text(AppStrings.chatStopButton), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);

    await _waitForReply(tester);
    expect(find.text(AppStrings.chatSendButton), findsOneWidget);
    expect(find.textContaining("'하늘'이 나오는 건 1행"), findsOneWidget);
  });

  testWidgets('중단하면 답을 기다리지 않고 다시 입력할 수 있다', (tester) async {
    await tester.pumpWidget(_app('seosi'));
    await tester.pumpAndSettle();

    await _send(tester, '잘 모르겠어요');
    await tester.tap(find.text(AppStrings.chatStopButton));
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);

    await _waitForReply(tester); // 늦게 온 답은 버린다
    expect(find.text(fallbackQuestions['seosi']!.first), findsNothing);
  });

  testWidgets('한 번에 200자를 넘게 입력할 수 없다', (tester) async {
    await tester.pumpWidget(_app('seosi'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '가' * 250);
    await tester.pump();
    expect(find.text(AppStrings.charCount(200, 200)), findsOneWidget);
  });

  testWidgets('힌트를 누르면 관찰 질문이 시트로 뜬다', (tester) async {
    await tester.pumpWidget(_app('seosi'));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.chatHintButton));
    await tester.pump();
    expect(find.text(AppStrings.chatHintTitle), findsOneWidget);

    await _waitForReply(tester);
    expect(find.text(fallbackQuestions['seosi']!.first), findsOneWidget);
  });
}
