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
  // 에셋이 실제로 묶였는지 여기서 본다 (pubspec.yaml의 assets/mascot/).
  testWidgets('마스코트 그림이 앱에 묶여 있다', (tester) async {
    final bytes = await rootBundle.load(AppLoading.assetPath);
    expect(bytes.lengthInBytes, greaterThan(0));
  });

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

  testWidgets('마스코트가 걸어간다', (tester) async {
    await pumpLoading(tester);

    // 기본 마스코트는 코드로 그린다 (CustomPaint는 프레임워크도 쓰므로 키로 찾는다)
    final mascot = find.byKey(AppLoading.defaultMascotKey);
    expect(mascot, findsOneWidget);

    final before = tester.getCenter(mascot);
    await tester.pump(const Duration(milliseconds: 300));
    final after = tester.getCenter(mascot);

    expect(
      before == after,
      isFalse,
      reason: '마스코트가 제자리에 멈춰 있다',
    );
  });

  testWidgets('애니메이션을 끈 기기에서는 돌지 않는다', (tester) async {
    await pumpLoading(tester, disableAnimations: true);

    // 돌고 있으면 여기서 시간 초과된다
    await tester.pumpAndSettle();

    final before = tester.getTopLeft(find.text('L'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.getTopLeft(find.text('L')), before);
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

  testWidgets('글자를 비우면 마스코트만 걷는다', (tester) async {
    await pumpLoading(tester, loading: const AppLoading(label: ''));

    expect(find.byType(Text), findsNothing);
    expect(find.byKey(AppLoading.defaultMascotKey), findsOneWidget);
  });

  group('LoadingPage', () {
    testWidgets('제목을 주면 앱바에 보인다', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoadingPage(title: '대조')),
      );

      expect(find.text('대조'), findsOneWidget);
      expect(find.byType(AppLoading), findsOneWidget);
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
