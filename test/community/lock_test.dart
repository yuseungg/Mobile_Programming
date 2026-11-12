// 주인: D — S08·S09의 잠금 (기획서 5장 「잠금 한 곳」)
// 저장하지 않은 시의 남의 대화는 어디서도 볼 수 없다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yeobaek/app/strings.dart';
import 'package:yeobaek/features/community/community_detail_screen.dart';
import 'package:yeobaek/features/community/community_list_screen.dart';
import 'package:yeobaek/features/community/locked_notice.dart';
import 'package:yeobaek/data/fakes/fake_data.dart';
import 'package:yeobaek/data/models/public_conversation.dart';
import 'package:yeobaek/data/models/reading.dart';
import 'package:yeobaek/data/repositories.dart';

import '../support/stub_reading_source.dart';

void main() {
  // source를 넘기지 않는 테스트는 화면 기본값(RepositoryReadingSource)으로 돈다.
  // 그쪽이 시연과 같은 경로이므로, 가짜 저장소를 깔고 그대로 시험한다.
  setUp(() => Repositories.useFakes(signedInUserId: FakeData.myUserId));
  group('S08 대화 목록', () {
    testWidgets('저장한 시(서시)는 대화 목록이 보인다', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: CommunityListScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(LockedNotice), findsNothing);
      expect(find.text(AppStrings.communityLockedTitle), findsNothing);
      expect(find.textContaining('#'), findsWidgets); // 첫 낱말 태그
    });

    testWidgets('S06에서 저장하면 그 시의 잠금이 풀린다 (저장소 연결)', (tester) async {
      // PR #8 리뷰에서 B가 짚은 지점. 화면이 저장소를 보지 않으면, 저장해도
      // S08은 「저장하지 않은 시」로 본다. 어댑터가 끼워졌는지를 여기서 지킨다.
      await tester.pumpWidget(const MaterialApp(home: CommunityListScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('진달래꽃'));
      await tester.pumpAndSettle();
      expect(find.byType(LockedNotice), findsOneWidget); // 아직 안 저장했다

      await Repositories.reading.saveInterpretation(
        FakeData.myUserId,
        const Reading(poemId: 'jindallae', interpretation: '진달래꽃 내 해석'),
        summary: null,
      );

      await tester.pumpWidget(const MaterialApp(home: CommunityListScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('진달래꽃'));
      await tester.pumpAndSettle();
      expect(find.byType(LockedNotice), findsNothing); // 이제 열린다
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

  group('S09 — 저장하지 않은 시 (읽기 포트로 덮음)', () {
    PublicConversation conversation(String poemId) => PublicConversation(
          conversationId: 'c1',
          userId: 'user_1',
          poemId: poemId,
          firstWord: '다짐',
          summary: '요약',
          interpretation: '남의 해석',
          empathyCount: 3,
          createdAt: DateTime.utc(2026, 11, 1),
        );

    testWidgets('저장하지 않았으면 내용 대신 잠금 안내', (tester) async {
      final source = StubReadingSource(
        conversations: [conversation('jindallae')],
        readings: const {}, // 아무 시도 저장하지 않았다
      );
      await tester.pumpWidget(
        MaterialApp(
          home: CommunityDetailScreen(
            conversationId: 'c1',
            source: source,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LockedNotice), findsOneWidget);
      expect(find.text('남의 해석'), findsNothing);
      expect(find.text(AppStrings.communityDetailInterpretation), findsNothing);
    });

    testWidgets('저장했으면 열린다', (tester) async {
      final source = StubReadingSource(
        conversations: [conversation('jindallae')],
        readings: const {
          'jindallae': Reading(poemId: 'jindallae', isSaved: true),
        },
      );
      await tester.pumpWidget(
        MaterialApp(
          home: CommunityDetailScreen(
            conversationId: 'c1',
            source: source,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LockedNotice), findsNothing);
      expect(find.text('남의 해석'), findsOneWidget);
    });
  });

  group('S08 — 작성자 닉네임을 미리 모은다', () {
    testWidgets('같은 사람의 카드가 여러 장이어도 한 번만 읽는다', (tester) async {
      final source = StubReadingSource(
        readings: const {'seosi': Reading(poemId: 'seosi', isSaved: true)},
        conversations: [
          for (var i = 1; i <= 3; i++)
            PublicConversation(
              conversationId: 'c$i',
              userId: 'user_1', // 세 장 모두 같은 사람
              poemId: 'seosi',
              firstWord: '낱말$i',
              summary: '요약',
              interpretation: '해석',
              empathyCount: 0,
              createdAt: DateTime.utc(2026, 11, i),
            ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(home: CommunityListScreen(source: source)),
      );
      await tester.pumpAndSettle();

      final profileCalls =
          source.calls.where((c) => c.startsWith('profileById:')).length;
      expect(profileCalls, 1);
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
