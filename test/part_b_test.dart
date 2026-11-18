import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// C: S01을 지나가는 도우미 — 다른 PR이 import 묶음 끝에 붙여도 겹치지 않게 위쪽에 둔다
import 'support/sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeobaek/features/intro/intro_screen.dart';
import 'package:yeobaek/app/router.dart';
import 'package:yeobaek/app/strings.dart';
import 'package:yeobaek/data/fakes/fake_data.dart';
import 'package:yeobaek/data/fakes/fake_reading_repository.dart';
import 'package:yeobaek/data/fakes/fake_store.dart';
import 'package:yeobaek/data/models/poem.dart';
import 'package:yeobaek/data/models/public_conversation.dart';
import 'package:yeobaek/data/models/reading.dart';
import 'package:yeobaek/data/models/user_profile.dart';
import 'package:yeobaek/data/repositories.dart';
import 'package:yeobaek/features/chat/chat_screen.dart';
import 'package:yeobaek/features/compare/comparison_screen.dart';
import 'package:yeobaek/features/home/home_screen.dart';
import 'package:yeobaek/features/reading/reading_screen.dart';
import 'package:yeobaek/features/save/pending_saves.dart';
import 'package:yeobaek/features/save/save_screen.dart';
import 'package:yeobaek/main.dart';
import 'package:yeobaek/shared/widgets/poem_view.dart';

// 테스트용: S04 멈춤 표시 저장만 실패하는 저장소
class _MarkFailsReadingRepository extends FakeReadingRepository {
  _MarkFailsReadingRepository(super.store);

  @override
  Future<void> setMarkedLine(String userId, String poemId, int lineNo, {required bool isMarked}) async {
    // 조금 있다 실패 (그 사이 화면에 먼저 표시되는지 보려고)
    await Future<void>.delayed(const Duration(milliseconds: 100));
    throw Exception('network');
  }
}

// 테스트용: 네트워크 끊긴 것처럼 저장만 실패하는 저장소
class _NetworkDownReadingRepository extends FakeReadingRepository {
  _NetworkDownReadingRepository(super.store);

  @override
  Future<String?> saveInterpretation(String userId, Reading reading, {required String? summary}) async {
    throw Exception('network');
  }
}

void main() {
  // 테스트마다 가짜 저장소 새로 (앞 테스트에서 저장한 게 안 남게)
  setUp(() {
    Repositories.useFakes();
    // 저장 실패 보관용 기기 저장소도 테스트마다 빈 걸로
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('B 흐름: S03 → S04 행 표시 → S05 → S06 → S07', (tester) async {
    Repositories.useFakes(signedOut: true); // C: 앱을 켜면 로그인 상태부터 본다 — S01부터 시작
    await tester.pumpWidget(const YeobaekApp());
    await tester.pumpAndSettle();

    await signInAsDemo(tester); // C: S01이 진짜 로그인을 하므로 데모 계정으로

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
    // 서시는 가짜 데이터에 하던 대화가 있어서 버튼이 '대화 이어 하기'
    await tester.scrollUntilVisible(
      find.text('대화 이어 하기'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('대화 이어 하기'));
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
    Repositories.useFakes(signedOut: true); // C: 앱을 켜면 로그인 상태부터 본다 — S01부터 시작
    await tester.pumpWidget(const YeobaekApp());
    await tester.pumpAndSettle();
    await signInAsDemo(tester); // C: S01이 진짜 로그인을 하므로 데모 계정으로

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

  testWidgets('대조 연 뒤에도 비공개였으면 공개로 바꿔 저장됨', (tester) async {
    Reading reading = (await Repositories.reading.fetchReading(FakeData.myUserId, 'jindallae'))!;
    await Repositories.reading.saveInterpretation(FakeData.myUserId, reading.copyWith(interpretation: '이별'), summary: null);
    await Repositories.reading.openComparison(FakeData.myUserId, 'jindallae');

    await tester.pumpWidget(const MaterialApp(
        onGenerateRoute: AppRouter.onGenerateRoute,
        home: SaveScreen(poemId: 'jindallae')));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.saveLockedNotice), findsOneWidget);

    await tester.tap(find.byType(SwitchListTile));
    await tester.pump();
    await tester.tap(find.text('저장하기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    List<PublicConversation> list = await Repositories.publicConversation.fetchForPoem('jindallae');
    expect(list.where((c) => c.userId == FakeData.myUserId && c.interpretation == '이별'), isNotEmpty);
  });

  testWidgets('이미 공개한 시는 공개 못 되돌리고 이유 보여줌', (tester) async {
    Reading reading = (await Repositories.reading.fetchReading(FakeData.myUserId, 'jindallae'))!;
    await Repositories.reading.saveInterpretation(FakeData.myUserId,
        reading.copyWith(interpretation: '이별', isPublic: true), summary: '요약');

    await tester.pumpWidget(const MaterialApp(home: SaveScreen(poemId: 'jindallae')));
    await tester.pumpAndSettle();

    SwitchListTile toggle = tester.widget(find.byType(SwitchListTile));
    expect(toggle.onChanged, isNull);
    expect(find.text(AppStrings.savePublicFixed), findsOneWidget);
  });

  // 홈은 탭 화면이라 라우터 붙여서 띄움
  Widget homeApp() {
    return const MaterialApp(onGenerateRoute: AppRouter.onGenerateRoute, home: HomeScreen());
  }

  testWidgets('대화하다 멈춘 시는 홈 이어 읽기에 뜨고 누르면 바로 대화로', (tester) async {
    await tester.pumpWidget(homeApp());
    await tester.pumpAndSettle();

    expect(find.text('이어 읽기'), findsOneWidget);
    Finder tile = find.widgetWithText(ListTile, '‘이별’에서 시작한 대화를 이어 가요'); // 진달래꽃
    expect(tile, findsOneWidget);

    await tester.tap(tile);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(ChatScreen), findsOneWidget);
  });

  testWidgets('S04 버튼은 하던 대화 있으면 대화 이어 하기', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ReadingScreen(poemId: 'jindallae')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('대화 이어 하기'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('대화 이어 하기'), findsOneWidget);
  });

  testWidgets('처음 읽는 시는 원래 문구 그대로', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ReadingScreen(poemId: 'bomgoyangi')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('이 낱말로 대화 시작'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('이 낱말로 대화 시작'), findsOneWidget);
  });

  testWidgets('저장하고 나면 이어 읽기에서 빠짐', (tester) async {
    Reading? reading = await Repositories.reading.fetchReading(FakeData.myUserId, 'jindallae');
    await Repositories.reading.saveInterpretation(FakeData.myUserId,
        reading!.copyWith(interpretation: '보내는 사람이 끝까지 꽃을 뿌리는 게 마음에 걸림'), summary: null);

    await tester.pumpWidget(homeApp());
    await tester.pumpAndSettle();
    expect(find.text('이어 읽기'), findsNothing);
  });

  //AI
  testWidgets('저장 실패하면 기기에 보관했다가 다음에 다시 저장함', (tester) async {
    FakeStore store = FakeStore();
    Repositories.reading = _NetworkDownReadingRepository(store);

    await tester.pumpWidget(const MaterialApp(
        onGenerateRoute: AppRouter.onGenerateRoute,
        home: SaveScreen(poemId: 'jindallae')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '보내는 사람이 끝까지 꽃을 뿌리는 게 마음에 걸림');
    await tester.pump();
    await tester.tap(find.text('저장하기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(AppStrings.saveKeptForLater), findsOneWidget);
    expect(find.byType(SaveScreen), findsOneWidget); // 저장 안 됐으니 대조로 안 넘어감

    // 네트워크 돌아옴
    Repositories.reading = FakeReadingRepository(store);
    int saved = await retryPendingSaves();
    expect(saved, 1);
    Reading? reading = await Repositories.reading.fetchReading(FakeData.myUserId, 'jindallae');
    expect(reading!.isSaved, true);
    expect(reading.interpretation, '보내는 사람이 끝까지 꽃을 뿌리는 게 마음에 걸림');
    expect(await retryPendingSaves(), 0); // 보관분은 지워짐
  });

  testWidgets('홈 열릴 때 보관해 둔 저장 다시 함', (tester) async {
    Reading? reading = await Repositories.reading.fetchReading(FakeData.myUserId, 'jindallae');
    await keepPendingSave(FakeData.myUserId, reading!.copyWith(interpretation: '꽃을 밟고 가라는 말이 오히려 붙잡는 말 같음'), null);

    await tester.pumpWidget(homeApp());
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.homePendingSaved), findsOneWidget);
    Reading? after = await Repositories.reading.fetchReading(FakeData.myUserId, 'jindallae');
    expect(after!.isSaved, true);
    expect(find.text('이어 읽기'), findsNothing); // 저장돼서 이어 읽기에서도 빠짐
  });


  test('보관한 뒤 대화 기록 지웠으면 다시 저장해도 대화 안 살아남', () async {
    Reading? reading = await Repositories.reading.fetchReading(FakeData.myUserId, 'jindallae');
    expect(reading!.conversation, isNotEmpty);
    await keepPendingSave(FakeData.myUserId, reading.copyWith(interpretation: '꽃을 밟고 가라는 말이 오히려 붙잡는 말 같음'), null);

    await Repositories.reading.clearConversations(FakeData.myUserId); // S11 기록 지우기
    expect(await retryPendingSaves(), 1);

    Reading? after = await Repositories.reading.fetchReading(FakeData.myUserId, 'jindallae');
    expect(after!.isSaved, true);
    expect(after.conversation, isEmpty);
  });

  test('보관한 뒤 S04에서 멈춘 행 바꿨으면 다시 저장해도 옛 값으로 안 덮음', () async {
    Reading? reading = await Repositories.reading.fetchReading(FakeData.myUserId, 'jindallae');
    await keepPendingSave(FakeData.myUserId, reading!.copyWith(interpretation: '꽃을 밟고 가라는 말이 오히려 붙잡는 말 같음'), null);

    // 보관한 다음에 S04에서 3행에 멈춤 표시
    await Repositories.reading.setMarkedLine(FakeData.myUserId, 'jindallae', 3, isMarked: true);
    expect(await retryPendingSaves(), 1);

    Reading? after = await Repositories.reading.fetchReading(FakeData.myUserId, 'jindallae');
    expect(after!.markedLines, contains(3));
    expect(after.interpretation, '꽃을 밟고 가라는 말이 오히려 붙잡는 말 같음');
  });

  //AI
  testWidgets('S04 멈춤 저장 실패하면 화면 되돌리고 안내', (tester) async {
    Repositories.reading = _MarkFailsReadingRepository(FakeStore());
    await tester.pumpWidget(const MaterialApp(home: ReadingScreen(poemId: 'bomgoyangi')));
    await tester.pumpAndSettle();

    // 봄은 고양이로다 1행은 멈춘 사람 3명. 멈춘 행이 되면 그 줄에 '3명'이 보임
    Finder firstLine = find.descendant(of: find.byType(PoemView), matching: find.byType(InkWell)).first;
    await tester.tap(firstLine);
    await tester.pump();
    expect(find.text('3명'), findsOneWidget); // 저장 기다리기 전에 먼저 표시

    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('3명'), findsNothing); // 저장 못 해서 되돌림
    expect(find.text(AppStrings.readingMarkFailed), findsOneWidget);
  });
}
