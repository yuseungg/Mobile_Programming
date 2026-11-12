// 주인: D — 뱃지 이미지와 누락 시 대체 표시
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yeobaek/features/profile/badge_image.dart';

Future<void> pumpBadge(WidgetTester tester, String poemId,
    {double size = 72}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: BadgeImage(poemId: poemId, size: size)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('에셋 경로 규칙', () {
    expect(BadgeImage.assetPathFor('seosi'), 'assets/badges/seosi.png');
  });

  testWidgets('이미지가 없으면 그 시를 닮은 아이콘으로 대신한다', (tester) async {
    await pumpBadge(tester, 'seosi');
    expect(find.byIcon(Icons.star_rounded), findsOneWidget);

    await pumpBadge(tester, 'jindallae');
    expect(find.byIcon(Icons.local_florist_rounded), findsOneWidget);

    await pumpBadge(tester, 'bomgoyangi');
    expect(find.byIcon(Icons.pets_rounded), findsOneWidget);
  });

  testWidgets('모르는 시도 깨지지 않는다', (tester) async {
    await pumpBadge(tester, 'unknown_poem');
    expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('크기를 따른다', (tester) async {
    await pumpBadge(tester, 'seosi', size: 48);
    final box = tester.getSize(find.byType(BadgeImage));
    expect(box.width, 48);
    expect(box.height, 48);
  });
}
