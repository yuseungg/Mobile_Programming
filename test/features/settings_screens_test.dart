// C — S10 설정 보기 · S11 설정 바꾸기 (요건 c · d)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yeobaek/app/router.dart';
import 'package:yeobaek/app/tab_shell.dart';
import 'package:yeobaek/data/fakes/fake_data.dart';
import 'package:yeobaek/data/models/settings.dart';
import 'package:yeobaek/data/repositories.dart';
import 'package:yeobaek/data/settings_options.dart';
import 'package:yeobaek/features/settings/settings_screen.dart';
import 'package:yeobaek/shared/widgets/app_button.dart';

void main() {
  setUp(Repositories.useFakes);

  // 기본 테스트 화면(800×600)은 S11 아래쪽(말투 · 기록 지우기)이 잘려 아예 만들어지지 않는다.
  // 세로로 긴 화면에서 돌린다.
  void useTallScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Future<void> pumpSettings(WidgetTester tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(const MaterialApp(
      home: SettingsScreen(),
      onGenerateRoute: AppRouter.onGenerateRoute,
    ));
    await tester.pumpAndSettle();
  }

  Future<void> openEdit(WidgetTester tester) async {
    final editButton = find.byType(AppPrimaryButton);
    await tester.ensureVisible(editButton);
    await tester.pumpAndSettle(); // 스크롤한 자리를 그려야 누를 수 있다
    await tester.tap(editButton);
    await tester.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pump();
  }

  TextButton saveButton(WidgetTester tester) =>
      tester.widget<TextButton>(find.widgetWithText(TextButton, '저장'));

  testWidgets('S10은 저장소의 설정과 이번 달 사용량을 보여준다', (tester) async {
    await Repositories.settings.save(defaultSettings.copyWith(tone: Tone.gentle));
    await Repositories.settings.countQuestionCall();

    await pumpSettings(tester);

    expect(find.text(defaultSettings.questionModel), findsOneWidget);
    expect(find.text(defaultSettings.comparisonModel), findsOneWidget);
    expect(find.text('부드럽게'), findsOneWidget);
    expect(
      find.text('질문 ${FakeData.usageQuestionCount + 1}회 · '
          '비교 ${FakeData.usageComparisonCount}회'),
      findsOneWidget,
    );
  });

  testWidgets('S11: 바뀐 게 없으면 저장 버튼이 꺼져 있다', (tester) async {
    await pumpSettings(tester);
    await openEdit(tester);

    expect(saveButton(tester).onPressed, isNull);

    await tapVisible(tester, find.text('부드럽게'));
    expect(saveButton(tester).onPressed, isNotNull);

    // 다시 원래대로 돌리면 다시 꺼진다
    await tapVisible(tester, find.text('담백하게'));
    expect(saveButton(tester).onPressed, isNull);
  });

  testWidgets('S11에서 바꾸고 저장하면 기억되고 S10에 바로 보인다', (tester) async {
    // 기본 질문 모델 · 비교 모델 둘 다와 다른 모델 — S10에 한 번만 보여야 한다
    final newQuestionModel = modelOptions
        .map((option) => option.model)
        .firstWhere((model) =>
            model != defaultSettings.questionModel &&
            model != defaultSettings.comparisonModel);

    await pumpSettings(tester);
    await openEdit(tester);

    // 모델 목록은 질문 · 비교 두 번 나온다. 첫째가 질문 모델
    await tapVisible(tester, find.text(newQuestionModel).first);
    await tapVisible(tester, find.text('부드럽게'));
    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = await Repositories.settings.load();
    expect(saved.questionModel, newQuestionModel);
    expect(saved.comparisonModel, defaultSettings.comparisonModel);
    expect(saved.tone, Tone.gentle);

    // S10으로 돌아와 새 값을 다시 읽었다
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.text('부드럽게'), findsOneWidget);
    expect(find.text(newQuestionModel), findsOneWidget);
    expect(find.text('설정을 저장했어요.'), findsOneWidget);
  });

  testWidgets('대화 기록 지우기: 취소하면 그대로, 지우면 대화만 비운다', (tester) async {
    Future<List<({bool hasConversation, bool isSaved, String interpretation})>>
        snapshot() async => [
              for (final reading in await Repositories.reading
                  .fetchMyReadings(FakeData.myUserId))
                (
                  hasConversation: reading.conversation.isNotEmpty,
                  isSaved: reading.isSaved,
                  interpretation: reading.interpretation,
                ),
            ];

    final before = await snapshot();
    expect(before.any((r) => r.hasConversation), isTrue);

    await pumpSettings(tester);
    await openEdit(tester);

    final deleteButton = find.widgetWithText(TextButton, '지우기');
    final dialog = find.byType(AlertDialog);

    // 취소
    await tester.ensureVisible(deleteButton);
    await tester.pumpAndSettle();
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();
    expect(find.text('대화 기록을 지울까요?'), findsOneWidget);
    await tester.tap(find.descendant(of: dialog, matching: find.text('취소')));
    await tester.pumpAndSettle();
    expect(await snapshot(), before);

    // 지우기
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: dialog, matching: find.text('지우기')));
    await tester.pumpAndSettle();

    final after = await snapshot();
    expect(after.every((r) => !r.hasConversation), isTrue);
    // 저장 여부 · 해석은 그대로
    expect([for (final r in after) (r.isSaved, r.interpretation)],
        [for (final r in before) (r.isSaved, r.interpretation)]);
    expect(find.text('대화 기록을 지웠어요.'), findsOneWidget);
  });

  testWidgets('설정 탭을 다시 누르면 사용량을 새로 읽는다', (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(const MaterialApp(
      home: TabShell(initialTab: AppTab.settings),
      onGenerateRoute: AppRouter.onGenerateRoute,
    ));
    await tester.pumpAndSettle();

    final usage = find.textContaining('질문 ${FakeData.usageQuestionCount}회');
    expect(usage, findsOneWidget);

    await Repositories.settings.countQuestionCall();
    await tester.tap(find.byIcon(Icons.menu_book_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('질문 ${FakeData.usageQuestionCount + 1}회'),
      findsOneWidget,
    );
  });
}
