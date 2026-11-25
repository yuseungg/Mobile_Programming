// 주인: B — 계절 테마 기반 (poem_theme.dart, theme_header.dart, mascot_notice.dart)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yeobaek/app/poem_theme.dart';
import 'package:yeobaek/data/fakes/fake_data.dart';
import 'package:yeobaek/data/models/poem.dart';
import 'package:yeobaek/shared/widgets/mascot_notice.dart';
import 'package:yeobaek/shared/widgets/theme_header.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('시마다 계절 테마가 정해져 있고 모르는 시는 기본', () {
    for (Poem poem in FakeData.poems) {
      // 시 새로 넣고 계절 안 정하면 여기서 걸림
      expect(YeobaekTheme.forPoem(poem.poemId), isNot(YeobaekTheme.defaults), reason: poem.poemId);
    }
    expect(YeobaekTheme.forPoem('jindallae').season, Season.spring);
    expect(YeobaekTheme.forPoem('bomgoyangi').season, Season.spring);
    expect(YeobaekTheme.forPoem('seosi').season, Season.winter);
    expect(YeobaekTheme.forPoem('theroadnottaken').season, Season.autumn);
    expect(YeobaekTheme.forPoem('없는시'), YeobaekTheme.defaults);
  });

  test('테마 그림이 다 앱에 묶여 있다', () async {
    List<String> paths = [
      AppImages.logo, AppImages.shelf, AppImages.paper,
      AppImages.mascotLocked, AppImages.mascotEmpty, AppImages.mascotError,
    ];
    for (YeobaekTheme theme in YeobaekTheme.all) {
      paths.add(theme.headerImage);
      paths.add(theme.mascot);
    }
    for (String path in paths) {
      // 파일 이름 틀리면 여기서 던짐
      ByteData data = await rootBundle.load(path);
      expect(data.lengthInBytes, greaterThan(0), reason: path);
    }
  });

  testWidgets('머리 띠는 그 계절 그림 · 마스코트에 제목이랑 오른쪽 버튼까지', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        appBar: ThemeHeader(
          theme: YeobaekTheme.winter,
          title: const Text('서시'),
          actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.translate))],
        ),
      ),
    ));

    List<String> assets = tester
        .widgetList<Image>(find.byType(Image))
        .map((image) => (image.image as AssetImage).assetName)
        .toList();
    expect(assets, containsAll([YeobaekTheme.winter.headerImage, YeobaekTheme.winter.mascot]));
    // 그림 못 불러올 때 보일 단색이 밑에 깔려 있음
    expect(
      find.byWidgetPredicate((w) => w is ColoredBox && w.color == YeobaekTheme.winter.headerTint),
      findsOneWidget,
    );
    expect(find.text('서시'), findsOneWidget);
    expect(find.byIcon(Icons.translate), findsOneWidget);
    expect(tester.getSize(find.byType(ThemeHeader)).height, greaterThanOrEqualTo(ThemeHeader.height));
  });

  testWidgets('마스코트 안내는 문구랑 버튼, 버튼 누르면 알려줌', (tester) async {
    int tapped = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MascotNotice(
          mood: MascotMood.error,
          message: '지금은 가져올 수 없어요.',
          actionLabel: '다시 시도',
          onAction: () => tapped++,
        ),
      ),
    ));

    Image image = tester.widget(find.byType(Image));
    expect((image.image as AssetImage).assetName, AppImages.mascotError);
    expect(find.text('지금은 가져올 수 없어요.'), findsOneWidget);
    await tester.tap(find.text('다시 시도'));
    expect(tapped, 1);
  });

  testWidgets('버튼 글자 없으면 문구만', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: MascotNotice(mood: MascotMood.empty, message: '아직 없어요.')),
    ));
    expect(find.byType(FilledButton), findsNothing);
  });
}
