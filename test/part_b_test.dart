import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yeobaek/features/intro/intro_screen.dart';
import 'package:yeobaek/app/router.dart';
import 'package:yeobaek/data/fakes/fake_data.dart';
import 'package:yeobaek/data/models/poem.dart';
import 'package:yeobaek/data/models/public_conversation.dart';
import 'package:yeobaek/data/models/reading.dart';
import 'package:yeobaek/data/models/user_profile.dart';
import 'package:yeobaek/data/repositories.dart';
import 'package:yeobaek/features/compare/comparison_screen.dart';
import 'package:yeobaek/features/home/home_screen.dart';
import 'package:yeobaek/features/reading/reading_screen.dart';
import 'package:yeobaek/features/save/save_screen.dart';
import 'package:yeobaek/main.dart';

void main() {
  // 테스트마다 가짜 저장소 새로 (앞 테스트에서 저장한 게 안 남게)
  setUp(() {
    Repositories.useFakes();
  });

  testWidgets('B 흐름: S03 → S04 행 표시 → S05 → S06 → S07', (tester) async {
    await tester.pumpWidget(const YeobaekApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('로그인'));
    await tester.tap(find.text('로그인'));
    await tester.pumpAndSettle();

    // 로그인 다음은 S13 안내다. 30초 기다리면 저절로 홈으로 넘어간다.
    await tester.pump(IntroScreen.autoAdvanceDelay);
    await tester.pumpAndSettle();

    //오늘의 시는 날마다 바뀌어서 목록에서 서시 고름
    final seosiTile = find.widgetWithText(ListTile,'서시');
    await tester.scrollUntilVisible(seosiTile, 200, scrollable: find.byType(Scrollable).first);

    await tester.tap(seosiTile);
    await tester.pumpAndSettle();

    expect(find.text('12명'), findsNothing);
    await tester.tap(find.text('한 점 부끄럼이 없기를,'));
    await tester.pumpAndSettle();
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

    // 첫 낱말이 저장소에 들어갔는지 (S05가 여기서 꺼내 씀)
    Reading? reading = await Repositories.reading.fetchReading(FakeData.myUserId, 'seosi');
    expect(reading!.firstWord, '부끄럼');
    expect(reading.markedLines, contains(2));

    await tester.tap(find.text('내 해석 정리하기'));
    await tester.pumpAndSettle();

    // 저장 버튼은 하단 고정이라 스크롤 안 함
    await tester.tap(find.text('저장하기'));
    await tester.pumpAndSettle();
    expect(find.byType(ComparisonScreen), findsOneWidget);
  });



  //AI
  test('오늘의 시는 추가된 순서로 하루에 한 편씩 돌아간다', () {
    List<Poem> poems = FakeData.poems;
    DateTime day = DateTime(2026,11,10, 9);
    Poem first =todayPoem(poems, day);
    int i = poems.indexOf(first);
    expect(todayPoem(poems, DateTime(2026, 11, 10, 23, 59)), first);


    // 목록 끝 다음 날엔 처음 시로 돌아가는지 확인
    for (int d = 1; d <= poems.length; d++) {
      Poem next = todayPoem(poems, day.add(Duration(days: d)));
        expect(next, poems[(i + d) % poems.length]);
    }
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
    await tester.pumpAndSettle();

    expect(find.text('8명'), findsOneWidget); // 저장돼 있던 6행
    await tester.scrollUntilVisible(find.byType(TextField), 200, scrollable: find.byType(Scrollable).first);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, '부끄러움');
  });


  testWidgets('S04 들어갔다 나오면 홈 누적일수 하루 늘어남', (tester) async {
    await tester.pumpWidget(const YeobaekApp());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('로그인'));
    await tester.tap(find.text('로그인'));
    await tester.pumpAndSettle();

    // 로그인 다음은 S13 안내다. 30초 기다리면 저절로 홈으로 넘어간다.
    await tester.pump(IntroScreen.autoAdvanceDelay);
    await tester.pumpAndSettle();
    expect(find.text('지금까지 12일 시를 읽었어요'), findsOneWidget);

    Finder seosiTile = find.widgetWithText(ListTile, '서시');
    await tester.scrollUntilVisible(seosiTile, 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(seosiTile);
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    // 가짜 데이터 마지막으로 센 날이 10월 7일이라 오늘 들어가면 +1
    await tester.scrollUntilVisible(find.text('지금까지 13일 시를 읽었어요'), -200, scrollable: find.byType(Scrollable).first);
    expect(find.text('지금까지 13일 시를 읽었어요'), findsOneWidget);
  });


  //AI
  testWidgets('해석 저장하면 저장됨으로 바뀌고 뱃지 받음', (tester) async {
    await tester.pumpWidget(const MaterialApp(
        onGenerateRoute: AppRouter.onGenerateRoute,
        home: SaveScreen(poemId: 'jindallae')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('저장하기'));
    await tester.pumpAndSettle();

    Reading? reading = await Repositories.reading.fetchReading(FakeData.myUserId, 'jindallae');
    expect(reading!.isSaved, true);
    UserProfile me = await Repositories.user.fetchProfile(FakeData.myUserId);
    expect(me.badgeIds, contains('jindallae'));
  });

  testWidgets('공개로 저장하면 요약 붙은 공개 대화 생김', (tester) async {
    // 공개 대화 목록은 로그인한 사람 기준으로 잠금 확인해서 로그인된 상태로 시작
    Repositories.useFakes(signedInUserId: FakeData.myUserId);
    await tester.pumpWidget(const MaterialApp(
        onGenerateRoute: AppRouter.onGenerateRoute,
        home: SaveScreen(poemId: 'jindallae')));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.byType(SwitchListTile), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pump();
    await tester.tap(find.text('저장하기'));
    // S07(D)은 불러오는 동안 스피너가 계속 돌아서 settle 말고 저장 끝날 만큼만 기다림
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    List<PublicConversation> list = await Repositories.publicConversation.fetchForPoem('jindallae');
    PublicConversation? mine;
    for (PublicConversation c in list) {
      if (c.userId == FakeData.myUserId) {
        mine = c;
      }
    }
    expect(mine, isNotNull);
    expect(mine!.summary.trim().isNotEmpty, true);
  });
}
