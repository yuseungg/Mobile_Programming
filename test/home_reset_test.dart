// 주인: B — 홈에서 대화한 시를 누르면 이어 읽기 / 초기화 (11/25 회의)
// 초기화 = 그 시의 첫 낱말 · 대화 · 근거 행 · 해석을 비우고 대조 잠금도 풀어서 처음부터 다시 읽기
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeobaek/app/router.dart';
import 'package:yeobaek/app/strings.dart';
import 'package:yeobaek/data/fakes/fake_data.dart';
import 'package:yeobaek/data/models/public_conversation.dart';
import 'package:yeobaek/data/models/reading.dart';
import 'package:yeobaek/data/repositories.dart';
import 'package:yeobaek/features/chat/chat_screen.dart';
import 'package:yeobaek/features/home/home_screen.dart';
import 'package:yeobaek/features/reading/reading_screen.dart';

void main() {
  final me = FakeData.myUserId;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Repositories.useFakes();
  });

  Widget homeApp() {
    return const MaterialApp(onGenerateRoute: AppRouter.onGenerateRoute, home: HomeScreen());
  }

  // 시 목록에서 누름 (진달래꽃은 위 이어 읽기에도 있어서 맨 아래 것)
  Future<void> tapPoem(WidgetTester tester, String title) async {
    Finder tile = find.widgetWithText(ListTile, title);
    await tester.scrollUntilVisible(tile, 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(tile.last);
    await tester.pumpAndSettle();
  }

  testWidgets('대화한 시를 누르면 이어 읽기 / 초기화를 고르고, 이어 읽기는 바로 대화로', (tester) async {
    await tester.pumpWidget(homeApp());
    await tester.pumpAndSettle();

    await tapPoem(tester, '서시');
    expect(find.widgetWithText(OutlinedButton, AppStrings.homeReset), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, AppStrings.homeContinueTitle));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(ChatScreen), findsOneWidget);
    expect(find.byType(ReadingScreen), findsNothing);
  });

  testWidgets('대화 안 한 시는 고르는 거 없이 바로 S04', (tester) async {
    await tester.pumpWidget(homeApp());
    await tester.pumpAndSettle();

    await tapPoem(tester, '봄은 고양이로다');
    expect(find.text(AppStrings.homeReset), findsNothing);
    expect(find.byType(ReadingScreen), findsOneWidget);
  });

  testWidgets('초기화하면 안내 뒤 대화 · 해석을 지우고 S04에서 첫 낱말부터', (tester) async {
    await tester.pumpWidget(homeApp());
    await tester.pumpAndSettle();

    await tapPoem(tester, '서시');
    await tester.tap(find.widgetWithText(OutlinedButton, AppStrings.homeReset));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.homeResetMessage), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, AppStrings.homeReset));
    await tester.pumpAndSettle();
    expect(find.byType(ReadingScreen), findsOneWidget);

    Reading after = (await Repositories.reading.fetchReading(me, 'seosi'))!;
    expect(after.firstWord, '');
    expect(after.conversation, isEmpty);
    expect(after.interpretation, '');
    expect(after.hasOpenedComparison, false);
    expect(after.isSaved, true); // 저장 · 뱃지는 그대로라 S07 · S08은 열린 채

    // 대화가 비었으니 첫 낱말 칸이 다시 열림
    await tester.scrollUntilVisible(find.byType(TextField), 200, scrollable: find.byType(Scrollable).first);
    TextField field = tester.widget(find.byType(TextField));
    expect(field.readOnly, false);
  });

  testWidgets('초기화 안내에서 취소하면 아무것도 안 지움', (tester) async {
    await tester.pumpWidget(homeApp());
    await tester.pumpAndSettle();

    await tapPoem(tester, '서시');
    await tester.tap(find.widgetWithText(OutlinedButton, AppStrings.homeReset));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.homeResetCancel));
    await tester.pumpAndSettle();

    expect(find.byType(ReadingScreen), findsNothing);
    Reading after = (await Repositories.reading.fetchReading(me, 'seosi'))!;
    expect(after.firstWord, '부끄러움');
    expect(after.conversation, isNotEmpty);
  });

  test('초기화하면 대조 잠금이 풀려서 새 해석을 저장하고, 공개 대화도 새 것으로 바뀜', () async {
    const poemId = 'theroadnottaken';
    await Repositories.reading.setMarkedLine(me, poemId, 3, isMarked: true);
    Reading marked = (await Repositories.reading.fetchReading(me, poemId))!;
    await Repositories.reading.saveInterpretation(
      me,
      marked.copyWith(firstWord: '길', interpretation: '옛 해석', isPublic: true, evidenceLines: const [3]),
      summary: '옛 요약',
    );
    await Repositories.reading.openComparison(me, poemId);

    await Repositories.reading.resetReading(me, poemId);
    Reading reset = (await Repositories.reading.fetchReading(me, poemId))!;
    expect(reset.interpretation, '');
    expect(reset.evidenceLines, isEmpty);
    expect(reset.markedLines, [3]); // 멈춘 행은 집계랑 같이 움직여서 그대로
    expect(reset.isPublic, true); // 공개는 되돌릴 수 없음

    // 빈 해석으로는 대조를 열어도 안 잠김 (잠기면 새 해석을 못 씀)
    await Repositories.reading.openComparison(me, poemId);
    expect((await Repositories.reading.fetchReading(me, poemId))!.hasOpenedComparison, false);

    await Repositories.reading.saveInterpretation(
      me,
      reset.copyWith(firstWord: '숲', interpretation: '새 해석', isPublic: true),
      summary: '새 요약',
    );
    List<PublicConversation> list = await Repositories.publicConversation.fetchForPoem(poemId);
    PublicConversation mine = list.firstWhere((c) => c.userId == me);
    expect(mine.interpretation, '새 해석');
    expect(mine.summary, '새 요약');
    expect(mine.firstWord, '숲');
    expect(list.where((c) => c.userId == me).length, 1); // 시마다 하나 그대로
  });
}
