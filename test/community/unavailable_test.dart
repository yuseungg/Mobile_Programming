// 주인: D — 읽기가 실패했을 때 화면이 멈추지 않는지
//
// C의 저장소는 저장하지 않은 시의 대화를 읽으면 ConversationsLockedException을
// 던진다. FutureBuilder가 에러를 보지 않으면 스피너가 영원히 돈다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yeobaek/app/strings.dart';
import 'package:yeobaek/features/community/community_detail_screen.dart';
import 'package:yeobaek/features/community/community_list_screen.dart';
import 'package:yeobaek/features/community/locked_notice.dart';
import 'package:yeobaek/features/profile/profile_screen.dart';

import '../support/pump.dart';
import '../support/stub_reading_source.dart';

void main() {
  StubReadingSource throwing() => StubReadingSource(throwOnRead: true);

  testWidgets('S08 — 목록을 못 읽으면 안내가 나오고 스피너가 멈춘다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: CommunityListScreen(source: throwing())),
    );
    await pumpUntilLoaded(tester);

    expect(find.byType(UnavailableNotice), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text(AppStrings.noticeUnavailable), findsOneWidget);
  });

  testWidgets('S09 — 대화를 못 읽으면 안내가 나온다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CommunityDetailScreen(
          conversationId: 'c1',
          source: throwing(),
        ),
      ),
    );
    await pumpUntilLoaded(tester);

    expect(find.byType(UnavailableNotice), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('S12 — 프로필을 못 읽으면 안내가 나온다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: ProfileScreen(userId: 'user_1', source: throwing())),
    );
    await pumpUntilLoaded(tester);

    expect(find.byType(UnavailableNotice), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('S08 — 이유를 단정하지 않는다 (잠금이라고 말하지 않는다)', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: CommunityListScreen(source: throwing())),
    );
    await pumpUntilLoaded(tester);

    // 네트워크 실패도 같은 자리로 오므로 "저장하면 열려요"라고 하면 거짓이 된다
    expect(find.text(AppStrings.communityLockedBody), findsNothing);
  });
}
