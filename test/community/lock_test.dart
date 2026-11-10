// 주인: D — S08·S09의 잠금 (기획서 5장 「잠금 한 곳」)
// 저장하지 않은 시의 남의 대화는 어디서도 볼 수 없다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yeobaek/app/strings.dart';
import 'package:yeobaek/features/community/community_detail_screen.dart';
import 'package:yeobaek/features/community/community_list_screen.dart';
import 'package:yeobaek/features/community/locked_notice.dart';

void main() {
  group('S08 대화 목록', () {
    testWidgets('저장한 시(서시)는 대화 목록이 보인다', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: CommunityListScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(LockedNotice), findsNothing);
      expect(find.text(AppStrings.communityLockedTitle), findsNothing);
      expect(find.textContaining('#'), findsWidgets); // 첫 낱말 태그
    });

    testWidgets('저장하지 않은 시를 고르면 목록 대신 잠금 안내', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: CommunityListScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('진달래꽃'));
      await tester.pumpAndSettle();

      expect(find.byType(LockedNotice), findsOneWidget);
      expect(find.text(AppStrings.communityLockedTitle), findsOneWidget);
      expect(find.text(AppStrings.communityLockedBody), findsOneWidget);
      // 남의 대화는 한 장도 남아 있지 않다
      expect(find.textContaining('#'), findsNothing);
    });

    testWidgets('잠긴 시 칩에는 자물쇠가 붙는다', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: CommunityListScreen()));
      await tester.pumpAndSettle();

      // 서시는 저장됨 → 자물쇠 없음, 나머지 둘은 잠김
      expect(find.byIcon(Icons.lock_outline), findsNWidgets(2));
    });

    testWidgets('다시 저장한 시로 돌아오면 목록이 돌아온다', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: CommunityListScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('진달래꽃'));
      await tester.pumpAndSettle();
      expect(find.byType(LockedNotice), findsOneWidget);

      await tester.tap(find.text('서시'));
      await tester.pumpAndSettle();
      expect(find.byType(LockedNotice), findsNothing);
      expect(find.textContaining('#'), findsWidgets);
    });
  });

  group('S09 대화 보기', () {
    testWidgets('저장한 시의 대화는 그대로 열린다', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CommunityDetailScreen(conversationId: 'post_1'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LockedNotice), findsNothing);
      expect(find.text(AppStrings.communityDetailFirstWord), findsOneWidget);
      expect(find.text(AppStrings.communityDetailInterpretation),
          findsOneWidget);
    });
  });

  group('LockedNotice', () {
    testWidgets('시가 있으면 읽으러 가기 버튼을 보여 준다', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: LockedNotice(poemId: 'seosi'))),
      );
      expect(find.text(AppStrings.communityLockedAction), findsOneWidget);
    });

    testWidgets('시가 없으면 버튼을 숨긴다', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: LockedNotice(poemId: null))),
      );
      expect(find.text(AppStrings.communityLockedAction), findsNothing);
      expect(find.text(AppStrings.communityLockedTitle), findsOneWidget);
    });
  });
}
