// 주인: D — S08 칩의 자물쇠가 탭을 다시 눌렀을 때 풀리는가
//
// 탭 화면은 IndexedStack 안에서 앱이 켜질 때 한 번 만들어지고 계속 살아 있다.
// 그래서 S06에서 해석을 저장하고 「모두의 대화」로 와도 칩은 잠긴 채였다.
// 다른 칩을 눌렀다 돌아오면 목록은 떴지만 자물쇠는 그대로였다 — 목록은
// 칩을 누를 때 다시 읽고, 자물쇠는 처음 한 번만 읽었기 때문이다.
// 앱을 껐다 켜야 풀렸다 (태블릿 점검).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yeobaek/app/strings.dart';
import 'package:yeobaek/data/models/public_conversation.dart';
import 'package:yeobaek/data/models/reading.dart';
import 'package:yeobaek/features/community/community_list_screen.dart';

import '../support/pump.dart';
import '../support/stub_reading_source.dart';

final _when = DateTime(2026, 11, 23);

void main() {
  late Map<String, Reading> readings;
  late StubReadingSource source;

  setUp(() {
    // 서시를 아직 저장하지 않은 상태로 시작한다
    readings = <String, Reading>{};
    source = StubReadingSource(
      readings: readings,
      todayPoemIdOverride: 'seosi',
      conversations: [
        PublicConversation(
          conversationId: 'post_1',
          userId: 'user_star_1',
          poemId: 'seosi',
          firstWord: '부끄러움',
          summaryKo: '부끄러움에서 시작한 대화예요.',
          summaryEn: 'A conversation that began with 부끄러움.',
          interpretation: '남의 해석.',
          empathyCount: 3,
          createdAt: _when,
        ),
      ],
    );
  });

  Future<void> pumpTab(WidgetTester tester, int openCount) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CommunityListScreen(openCount: openCount, source: source),
      ),
    );
    await pumpUntilLoaded(tester);
    // 자물쇠 다시 읽기는 스피너를 띄우지 않는다 (일부러 그렇게 뒀다).
    // pumpUntilLoaded는 스피너만 보므로 여기서 한 번 더 재운다.
    await tester.pumpAndSettle();
  }

  /// S06에서 저장한 것과 같은 효과
  void saveSeosi() {
    readings['seosi'] = const Reading(
      poemId: 'seosi',
      interpretation: '내 해석',
      isSaved: true,
    );
  }

  /// 서시 칩 안의 자물쇠만 본다. 저장하지 않은 다른 시는 잠긴 채로 남아야 한다.
  Finder seosiChipLock() => find.descendant(
        of: find.ancestor(
          of: find.text('서시'),
          matching: find.byType(ChoiceChip),
        ),
        matching: find.byIcon(Icons.lock_outline),
      );

  testWidgets('저장하고 탭을 다시 누르면 자물쇠가 풀리고 목록이 뜬다', (tester) async {
    await pumpTab(tester, 0);

    // 아직 잠겨 있다
    expect(seosiChipLock(), findsOneWidget);
    expect(find.text(AppStrings.communityLockedTitle), findsOneWidget);
    final lockedBefore = find.byIcon(Icons.lock_outline).evaluate().length;

    saveSeosi();

    // 탭을 다시 누른다 (화면은 그대로 살아 있고 openCount만 바뀐다)
    await pumpTab(tester, 1);

    expect(
      seosiChipLock(),
      findsNothing,
      reason: '서시 칩의 자물쇠가 그대로 남았다',
    );
    expect(find.text(AppStrings.communityLockedTitle), findsNothing);
    expect(find.textContaining('부끄러움'), findsWidgets);

    // 저장하지 않은 시는 잠긴 채로 둔다 — 전부 풀어 버리면 안 된다
    expect(
      find.byIcon(Icons.lock_outline).evaluate().length,
      lessThan(lockedBefore),
    );
    expect(find.byIcon(Icons.lock_outline), findsWidgets);
  });

  testWidgets('탭을 다시 눌러도 바뀐 게 없으면 목록을 다시 읽지 않는다', (tester) async {
    saveSeosi();
    await pumpTab(tester, 0);
    expect(find.textContaining('부끄러움'), findsWidgets);

    source.calls.clear();
    await pumpTab(tester, 1);

    // 자물쇠는 다시 보지만(readingFor) 목록과 닉네임은 그대로 둔다
    expect(
      source.calls.where((c) => c == 'conversationsFor:seosi'),
      isEmpty,
      reason: '바뀐 게 없는데 목록을 다시 불러왔다',
    );
    expect(
      source.calls.where((c) => c.startsWith('profileById:')),
      isEmpty,
      reason: '바뀐 게 없는데 닉네임을 다시 읽었다',
    );
    expect(find.textContaining('부끄러움'), findsWidgets);
  });

  testWidgets('자물쇠를 다시 읽다 실패해도 보던 화면을 지우지 않는다', (tester) async {
    saveSeosi();
    await pumpTab(tester, 0);
    expect(find.textContaining('부끄러움'), findsWidgets);

    // 탭을 다시 누르는 순간 읽기가 끊긴다
    source.throwOnRead = true;
    await pumpTab(tester, 1);

    expect(
      find.textContaining('부끄러움'),
      findsWidgets,
      reason: '다시 읽기가 실패했다고 보던 목록이 사라졌다',
    );
  });

  testWidgets('openCount가 그대로면 아무것도 다시 읽지 않는다', (tester) async {
    await pumpTab(tester, 0);
    source.calls.clear();

    await pumpTab(tester, 0);

    expect(source.calls, isEmpty);
  });
}
