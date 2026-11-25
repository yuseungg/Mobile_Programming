// 주인: D — S08 목록이 S09에서 돌아올 때 다시 읽는지 (C의 지적)
//
// 목록은 시를 고를 때 한 번만 불러왔다. 그래서 상세에서 공감을 눌러도
// 돌아온 목록의 공감 수는 그대로였다. 그 상태로 돌아가면 이 테스트가 깨진다.
//
// 목록 **전체**를 다시 불러오는 것으로 고치면 두 번째 묶음이 깨진다.
// 깜빡임과 닉네임 재조회를 막기 위해, 들어갔던 카드 하나만 다시 읽는다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yeobaek/app/router.dart';
import 'package:yeobaek/data/fakes/fake_data.dart';
import 'package:yeobaek/data/models/public_conversation.dart';
import 'package:yeobaek/data/models/reading.dart';
import 'package:yeobaek/data/repositories.dart';
import 'package:yeobaek/features/community/community_detail_screen.dart';
import 'package:yeobaek/features/community/community_list_screen.dart';

import '../support/pump.dart';
import '../support/stub_reading_source.dart';

final _when = DateTime(2026, 11, 19);

void main() {
  group('S09에서 공감하고 돌아오면 (화면 기본값 = RepositoryReadingSource)', () {
    setUp(() => Repositories.useFakes(signedInUserId: FakeData.myUserId));

    testWidgets('목록의 공감 수가 올라간다', (tester) async {
      // 라우터를 끼운다 — 카드를 누르면 실제 S09로 간다.
      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRouter.onGenerateRoute,
          home: const CommunityListScreen(),
        ),
      );
      await pumpUntilLoaded(tester);

      // post_1은 가짜 데이터에서 14다. 다른 카드와 숫자가 겹치지 않는다.
      final before = FakeData.publicConversations
          .firstWhere((c) => c.conversationId == 'post_1')
          .empathyCount;
      expect(find.text('$before'), findsOneWidget);

      await tester.tap(find.text('$before'));
      await tester.pumpAndSettle();

      // S09에서 공감을 누른다. 화면이 넘어가는 동안은 목록도 트리에 남아
      // 있어서, 하트를 상세 화면 안에서만 찾는다. 요약·해석이 길어 버튼이
      // 800×600 밖에 있으므로 스크롤해 올린 뒤 누른다.
      final heart = find.descendant(
        of: find.byType(CommunityDetailScreen),
        matching: find.byIcon(Icons.favorite_border),
      );
      await tester.ensureVisible(heart);
      await tester.pumpAndSettle();
      await tester.tap(heart);
      await tester.pumpAndSettle();

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('${before + 1}'), findsOneWidget);
      expect(find.text('$before'), findsNothing);
    });
  });

  group('돌아올 때 다시 읽는 범위', () {
    // 상세 화면 대신 바로 돌아올 수 있는 빈 화면을 띄운다. 여기서 보는 것은
    // 목록이 무엇을 다시 읽는가뿐이다.
    Route<dynamic> popOnTap(RouteSettings settings) {
      return MaterialPageRoute<void>(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('뒤로'),
            ),
          ),
        ),
      );
    }

    StubReadingSource sourceWith({int empathyCount = 7}) => StubReadingSource(
          readings: const {'seosi': Reading(poemId: 'seosi', isSaved: true)},
          conversations: [
            PublicConversation(
              conversationId: 'c1',
              userId: 'user_1',
              poemId: 'seosi',
              firstWord: '낱말',
              summaryKo: '요약',
              summaryEn: 'Summary',
              interpretation: '해석',
              empathyCount: empathyCount,
              createdAt: _when,
            ),
          ],
        );

    Future<void> openAndComeBack(
      WidgetTester tester,
      StubReadingSource source, {
      PublicConversation? changeTo,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: popOnTap,
          home: CommunityListScreen(source: source),
        ),
      );
      await pumpUntilLoaded(tester);

      await tester.tap(find.textContaining('낱말'));
      await tester.pumpAndSettle();

      // 상세에 머무는 동안 저장소에서 공감 수가 바뀐 상황
      if (changeTo != null) source.replaceConversation(changeTo);

      await tester.tap(find.text('뒤로'));
      await tester.pumpAndSettle();
    }

    testWidgets('그 카드 하나만 다시 읽는다', (tester) async {
      final source = sourceWith();
      await openAndComeBack(tester, source);

      expect(source.calls, contains('conversationById:c1'));
      // 목록 전체를 다시 불러오지 않는다 — 처음 한 번뿐
      expect(
        source.calls.where((c) => c == 'conversationsFor:seosi'),
        hasLength(1),
      );
      // 닉네임도 다시 읽지 않는다
      expect(
        source.calls.where((c) => c == 'profileById:user_1'),
        hasLength(1),
      );
    });

    testWidgets('바뀐 공감 수가 목록에 보인다', (tester) async {
      final source = sourceWith();
      await openAndComeBack(
        tester,
        source,
        changeTo: PublicConversation(
          conversationId: 'c1',
          userId: 'user_1',
          poemId: 'seosi',
          firstWord: '낱말',
          summaryKo: '요약',
          summaryEn: 'Summary',
          interpretation: '해석',
          empathyCount: 8,
          createdAt: _when,
        ),
      );

      expect(find.text('8'), findsOneWidget);
      expect(find.text('7'), findsNothing);
    });

    testWidgets('돌아오는 사이에 스피너가 끼어들지 않는다', (tester) async {
      final source = sourceWith();
      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: popOnTap,
          home: CommunityListScreen(source: source),
        ),
      );
      await pumpUntilLoaded(tester);

      await tester.tap(find.textContaining('낱말'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('뒤로'));

      // 한 프레임씩 밀면서 — 카드가 사라졌다 돌아오면 깜빡임이다
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 20));
        expect(find.byType(CircularProgressIndicator), findsNothing);
      }
      expect(find.textContaining('낱말'), findsOneWidget);
    });

    testWidgets('다시 읽기가 실패하면 목록을 그대로 둔다', (tester) async {
      final source = sourceWith();
      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: popOnTap,
          home: CommunityListScreen(source: source),
        ),
      );
      await pumpUntilLoaded(tester);

      await tester.tap(find.textContaining('낱말'));
      await tester.pumpAndSettle();

      source.throwOnRead = true; // 상세에 머무는 동안 읽기가 끊겼다
      await tester.tap(find.text('뒤로'));
      await tester.pumpAndSettle();

      expect(find.text('7'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
