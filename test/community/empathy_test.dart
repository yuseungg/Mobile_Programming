// 주인: D — S09 공감이 C의 저장소에 쓰이는지 (기획서 9장)
//
// 공감 버튼은 오래 화면 안에서만 바뀌었다. 눌러도 저장되지 않았고, 다시 열면
// 빈 하트로 돌아갔다. 이 테스트는 그 상태로 돌아가면 깨진다.
//
// 공감 수는 우열·순위에 쓰이지 않는다 (제품 원칙 3). 여기서 지키는 것은
// "내가 누른 것이 남는가"뿐이고, 목록 정렬은 건드리지 않는다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yeobaek/app/strings.dart';
import 'package:yeobaek/data/fakes/fake_data.dart';
import 'package:yeobaek/data/models/public_conversation.dart';
import 'package:yeobaek/data/models/reading.dart';
import 'package:yeobaek/data/repositories.dart';
import 'package:yeobaek/features/community/community_detail_screen.dart';

import '../support/pump.dart';
import '../support/stub_reading_source.dart';

void main() {
  final heartOn = find.byIcon(Icons.favorite);
  final heartOff = find.byIcon(Icons.favorite_border);

  // 실제 가짜 데이터의 요약·해석이 길어서 공감 버튼이 800×600 밖으로 밀린다.
  // 화면을 스크롤해 올린 뒤 누른다 (사람이 하는 것과 같다).
  Future<void> tapHeart(WidgetTester tester, Finder heart) async {
    await tester.ensureVisible(heart);
    await tester.pumpAndSettle();
    await tester.tap(heart);
    await tester.pumpAndSettle();
  }

  Future<void> openDetail(WidgetTester tester, {StubReadingSource? source}) {
    return tester.pumpWidget(
      MaterialApp(
        home: source == null
            ? const CommunityDetailScreen(conversationId: 'post_1')
            : CommunityDetailScreen(
                conversationId: 'post_1',
                source: source,
              ),
      ),
    );
  }

  group('저장소 연결 (화면 기본값 = RepositoryReadingSource)', () {
    // 시연과 같은 경로로 시험한다. 서시는 저장해 두어야 대화가 열린다.
    setUp(() async {
      Repositories.useFakes(signedInUserId: FakeData.myUserId);
      await Repositories.reading.saveInterpretation(
        FakeData.myUserId,
        const Reading(poemId: 'seosi', interpretation: '서시 내 해석'),
        summary: null,
      );
    });

    testWidgets('누르면 C의 저장소에 남는다', (tester) async {
      await openDetail(tester);
      await pumpUntilLoaded(tester);

      expect(heartOff, findsOneWidget);
      expect(
        await Repositories.publicConversation
            .hasEmpathized('post_1', FakeData.myUserId),
        isFalse,
      );

      await tapHeart(tester, heartOff);

      expect(heartOn, findsOneWidget);
      expect(
        await Repositories.publicConversation
            .hasEmpathized('post_1', FakeData.myUserId),
        isTrue,
      );
    });

    testWidgets('다시 열어도 눌린 채로 남는다', (tester) async {
      await openDetail(tester);
      await pumpUntilLoaded(tester);
      await tapHeart(tester, heartOff);

      // 화면을 처음부터 다시 띄운다 (앱을 껐다 켠 것과 같다)
      await openDetail(tester);
      await pumpUntilLoaded(tester);

      expect(heartOn, findsOneWidget);
      expect(heartOff, findsNothing);
    });

    testWidgets('한 번 더 누르면 꺼지고 저장소에서도 빠진다', (tester) async {
      await openDetail(tester);
      await pumpUntilLoaded(tester);
      await tapHeart(tester, heartOff);
      await tapHeart(tester, heartOn);

      expect(heartOff, findsOneWidget);
      expect(
        await Repositories.publicConversation
            .hasEmpathized('post_1', FakeData.myUserId),
        isFalse,
      );
    });

    testWidgets('공감 수는 저장소 값을 따라간다 — 내 것을 두 번 더하지 않는다', (tester) async {
      final before = (await Repositories.publicConversation
              .fetchById('post_1'))
          .empathyCount;

      await openDetail(tester);
      await pumpUntilLoaded(tester);
      expect(find.text(AppStrings.communityDetailEmpathyCount(before)),
          findsOneWidget);

      await tapHeart(tester, heartOff);
      expect(find.text(AppStrings.communityDetailEmpathyCount(before + 1)),
          findsOneWidget);

      // 다시 열었을 때 before+2가 되면 내 공감을 두 번 센 것이다
      await openDetail(tester);
      await pumpUntilLoaded(tester);
      expect(find.text(AppStrings.communityDetailEmpathyCount(before + 1)),
          findsOneWidget);
    });
  });

  group('저장이 실패하면', () {
    StubReadingSource stubWith({
      bool throwOnSetEmpathy = false,
      Set<String> empathized = const {},
    }) =>
        StubReadingSource(
          readings: const {
            'seosi': Reading(
              poemId: 'seosi',
              interpretation: '서시 내 해석',
              isSaved: true,
            ),
          },
          conversations: [
            PublicConversation(
              conversationId: 'post_1',
              userId: 'user_star_1',
              poemId: 'seosi',
              firstWord: '부끄러움',
              summary: '부끄러움에서 시작한 대화예요.',
              interpretation: '내 해석.',
              empathyCount: 14,
              createdAt: DateTime(2026, 11, 18),
            ),
          ],
          empathized: empathized,
          throwOnSetEmpathy: throwOnSetEmpathy,
        );

    testWidgets('눌린 모양을 되돌리고 알린다', (tester) async {
      final source = stubWith(throwOnSetEmpathy: true);
      await openDetail(tester, source: source);
      await pumpUntilLoaded(tester);

      await tapHeart(tester, heartOff);

      // 되돌아왔다 — 공감한 줄로 알게 두지 않는다
      expect(heartOff, findsOneWidget);
      expect(heartOn, findsNothing);
      expect(find.text(AppStrings.communityDetailEmpathyCount(14)),
          findsOneWidget);
      expect(
        find.text(AppStrings.communityDetailEmpathyFailed),
        findsOneWidget,
      );
      expect(source.calls, contains('setEmpathy:post_1:true'));
    });

    testWidgets('성공하면 알림을 띄우지 않는다', (tester) async {
      await openDetail(tester, source: stubWith());
      await pumpUntilLoaded(tester);

      await tapHeart(tester, heartOff);

      expect(heartOn, findsOneWidget);
      expect(find.text(AppStrings.communityDetailEmpathyFailed), findsNothing);
    });
  });

  group('처음 그릴 때', () {
    testWidgets('이미 공감한 대화는 켜진 하트로 연다', (tester) async {
      final source = StubReadingSource(
        readings: const {
          'seosi': Reading(
            poemId: 'seosi',
            interpretation: '서시 내 해석',
            isSaved: true,
          ),
        },
        conversations: [
          PublicConversation(
            conversationId: 'post_1',
            userId: 'user_star_1',
            poemId: 'seosi',
            firstWord: '부끄러움',
            summary: '부끄러움에서 시작한 대화예요.',
            interpretation: '내 해석.',
            empathyCount: 14,
            createdAt: DateTime(2026, 11, 18),
          ),
        ],
        empathized: const {'post_1'},
      );

      await openDetail(tester, source: source);
      await pumpUntilLoaded(tester);

      expect(heartOn, findsOneWidget);
      expect(source.calls, contains('hasEmpathized:post_1'));
    });
  });
}
