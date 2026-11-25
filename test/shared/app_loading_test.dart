// 주인: D — 공용 로딩 (lib/shared/widgets/app_loading.dart)
//
// 지키려는 것은 네 가지다.
//  1. 글자가 빠짐없이 보인다 (한 글자씩 따로 그리므로 빠지면 눈에 안 띈다)
//  2. 시간이 지나면 글자가 **움직인다** — 멈춘 게 아니라는 것이 이 위젯의 일이다
//  3. 애니메이션을 끈 기기에서는 돌지 않는다 (그 설정을 쓰는 사람과 pumpAndSettle)
//  4. 마스코트를 갈아 끼울 수 있다 (진짜 그림이 생기면 그 길로 들어온다)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:yeobaek/app/strings.dart';
import 'package:yeobaek/shared/widgets/app_loading.dart';

import '../support/pump.dart';

void main() {
  // 그림이 빠지면 화면에는 모래시계 아이콘이 대신 뜬다 — 눈에 잘 띄지 않으므로
  // 16장이 다 묶였는지 여기서 본다 (pubspec.yaml의 assets/mascot/).
  // 한 장만 빠져도 그 장에서 넘김이 끊긴다.
  testWidgets('마스코트 그림 16장이 다 앱에 묶여 있다', (tester) async {
    for (var i = 0; i < AppLoading.frameCount; i++) {
      final path = AppLoading.frameAsset(i);
      final bytes = await rootBundle.load(path);
      expect(bytes.lengthInBytes, greaterThan(0), reason: '$path 가 비었다');
    }
  });

  test('장 이름은 01부터 16까지 두 자리로 센다', () {
    expect(AppLoading.frameAsset(0), 'assets/mascot/mascot_01.png');
    expect(AppLoading.frameAsset(15), 'assets/mascot/mascot_16.png');
  });

  // ── 무엇을 기다리는지 적는 한 줄 ──
  // 이 로딩은 S06 저장 → S07 대조 사이에서만 쓴다. 그 기다림이 길어서
  // (저장소 쓰기 + 모델이 비교 문장을 쓰는 시간) 글자만으로는 왜 기다리는지
  // 알 수 없다. 그래서 한 줄을 받는다.

  Future<void> pumpLoading(
    WidgetTester tester, {
    Widget loading = const AppLoading(),
    bool disableAnimations = false,
  }) {
    return tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: MaterialApp(home: Scaffold(body: Center(child: loading))),
      ),
    );
  }

  testWidgets('글자를 한 글자씩 다 보여 준다', (tester) async {
    await pumpLoading(tester);

    // 'LOADING......' — 한 글자씩 따로 그려지므로 Text 위젯이 글자 수만큼 있다
    expect(
      find.byType(Text),
      findsNWidgets(AppStrings.loadingLabel.length),
    );
    expect(find.text('L'), findsOneWidget);
    expect(find.text('G'), findsOneWidget);
    // 점은 6개다 — 파도가 끝까지 이어지는지 눈으로 보는 부분이다
    expect(find.text('.'), findsNWidgets(6));
  });

  testWidgets('시간이 지나면 글자가 움직인다', (tester) async {
    await pumpLoading(tester);

    final before = tester.getTopLeft(find.text('L'));
    await tester.pump(const Duration(milliseconds: 120));
    final after = tester.getTopLeft(find.text('L'));

    expect(after.dy, isNot(before.dy), reason: '글자가 튀지 않았다');
    expect(after.dx, before.dx, reason: '위아래로만 튄다 — 옆으로는 가지 않는다');
  });

  /// 지금 그리고 있는 마스코트 그림의 경로
  String shownFrame(WidgetTester tester) {
    final image = tester.widget<Image>(find.byKey(AppLoading.defaultMascotKey));
    return (image.image as AssetImage).assetName;
  }

  testWidgets('시간이 지나면 다음 장으로 넘어간다', (tester) async {
    await pumpLoading(tester);

    expect(shownFrame(tester), AppLoading.frameAsset(0));

    // 한 바퀴가 1400밀리초 / 16장 → 장당 87.5밀리초
    await tester.pump(const Duration(milliseconds: 100));
    expect(shownFrame(tester), AppLoading.frameAsset(1));

    await tester.pump(const Duration(milliseconds: 100));
    expect(shownFrame(tester), AppLoading.frameAsset(2));
  });

  testWidgets('한 바퀴 동안 16장을 모두 지난다', (tester) async {
    await pumpLoading(tester);

    final seen = <String>{};
    for (var i = 0; i < 40; i++) {
      seen.add(shownFrame(tester));
      await tester.pump(const Duration(milliseconds: 40));
    }

    expect(seen, hasLength(AppLoading.frameCount), reason: '지나간 장: $seen');
  });

  testWidgets('마지막 장을 넘어가지 않는다', (tester) async {
    await pumpLoading(tester);

    // 한 바퀴의 끝자락 — 반올림이 어긋나면 17번째 장을 찾다가 깨진다
    await tester.pump(const Duration(milliseconds: 1399));
    expect(shownFrame(tester), AppLoading.frameAsset(15));

    await tester.pump(const Duration(milliseconds: 1));
    expect(shownFrame(tester), AppLoading.frameAsset(0));
  });

  testWidgets('애니메이션을 끈 기기에서는 돌지 않는다', (tester) async {
    await pumpLoading(tester, disableAnimations: true);

    // 돌고 있으면 여기서 시간 초과된다
    await tester.pumpAndSettle();

    final beforeLetter = tester.getTopLeft(find.text('L'));
    final beforeFrame = shownFrame(tester);
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.getTopLeft(find.text('L')), beforeLetter);
    expect(shownFrame(tester), beforeFrame, reason: '장이 넘어갔다');
    // 글자는 그대로 보인다 — 멈춰 있을 뿐이다
    expect(find.text('L'), findsOneWidget);
  });

  testWidgets('마스코트를 갈아 끼울 수 있다', (tester) async {
    await pumpLoading(
      tester,
      loading: const AppLoading(
        mascot: Icon(Icons.pets_rounded, key: Key('진짜그림')),
      ),
    );

    expect(find.byKey(const Key('진짜그림')), findsOneWidget);
    // 끼웠으면 코드로 그린 기본 마스코트는 그리지 않는다
    expect(find.byKey(AppLoading.defaultMascotKey), findsNothing);
  });

  testWidgets('글자를 비우면 마스코트만 남는다', (tester) async {
    await pumpLoading(tester, loading: const AppLoading(label: ''));

    expect(find.byType(Text), findsNothing);
    expect(find.byKey(AppLoading.defaultMascotKey), findsOneWidget);
  });

  testWidgets('문구를 주면 글자 아래 한 줄로 보인다', (tester) async {
    await pumpLoading(
      tester,
      loading: const AppLoading(
        message: AppStrings.loadingSavingConversation,
      ),
    );

    expect(find.text(AppStrings.loadingSavingConversation), findsOneWidget);
    // 파도치는 글자보다 아래에 있다
    final letter = tester.getTopLeft(find.text('L'));
    final line =
        tester.getTopLeft(find.text(AppStrings.loadingSavingConversation));
    expect(line.dy, greaterThan(letter.dy));
  });

  testWidgets('문구는 함께 튀지 않는다 — 읽는 줄이기 때문이다', (tester) async {
    await pumpLoading(
      tester,
      loading: const AppLoading(
        message: AppStrings.loadingSavingConversation,
      ),
    );

    final finder = find.text(AppStrings.loadingSavingConversation);
    final before = tester.getTopLeft(finder);
    await tester.pump(const Duration(milliseconds: 120));

    // 글자는 움직인다 (위 테스트) — 이 줄은 그대로여야 한다
    expect(tester.getTopLeft(finder), before);
  });

  testWidgets('문구를 주지 않으면 그 줄을 그리지 않는다', (tester) async {
    await pumpLoading(tester);

    // 한 글자씩 그린 Text만 있다 — 한 줄이 더 끼면 여기서 수가 어긋난다
    expect(find.byType(Text), findsNWidgets(AppStrings.loadingLabel.length));
  });

  testWidgets('문구만 주고 글자를 비울 수도 있다', (tester) async {
    await pumpLoading(
      tester,
      loading: const AppLoading(label: '', message: '저장하고 있어요'),
    );

    expect(find.byType(Text), findsOneWidget);
    expect(find.text('저장하고 있어요'), findsOneWidget);
  });

  group('LoadingPage', () {
    testWidgets('제목을 주면 앱바에 보인다', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoadingPage(title: '대조')),
      );

      expect(find.text('대조'), findsOneWidget);
      expect(find.byType(AppLoading), findsOneWidget);
    });

    testWidgets('문구를 AppLoading으로 넘긴다', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoadingPage(message: AppStrings.loadingSavingConversation),
        ),
      );

      expect(find.text(AppStrings.loadingSavingConversation), findsOneWidget);
    });

    testWidgets('제목이 없으면 앱바를 두지 않는다', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoadingPage()));

      expect(find.byType(AppBar), findsNothing);
      expect(find.byType(AppLoading), findsOneWidget);
    });

    testWidgets('라우트로 띄울 수 있다', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const LoadingPage()),
              ),
              child: const Text('가기'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('가기'));
      // 전환 애니메이션만 지나가게 민다 (로딩은 끝나지 않으므로 settle은 못 쓴다)
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(LoadingPage), findsOneWidget);
    });
  });

  testWidgets('pumpUntilLoaded가 이 위젯도 기다린다', (tester) async {
    // 300ms 뒤에 끝나는 Future. 그동안 AppLoading을 보여 준다.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FutureBuilder<String>(
            future: Future<String>.delayed(
              const Duration(milliseconds: 300),
              () => '다 왔다',
            ),
            builder: (context, snapshot) => snapshot.hasData
                ? Text(snapshot.data!)
                : const AppLoading(),
          ),
        ),
      ),
    );

    // 스피너만 보는 helper라면 여기서 바로 돌아와 아래 expect가 깨진다
    await pumpUntilLoaded(tester);

    expect(find.text('다 왔다'), findsOneWidget);
    expect(find.byType(AppLoading), findsNothing);
  });
}
