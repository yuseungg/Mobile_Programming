// S05 대화 화면 (A) — 키 없이 돌리면 가짜 에이전트가 답한다
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yeobaek/agent/prompts/fallback_questions.dart';
import 'package:yeobaek/app/router.dart';
import 'package:yeobaek/app/strings.dart';
import 'package:yeobaek/app/theme.dart';
import 'package:yeobaek/data/fakes/fake_data.dart';
import 'package:yeobaek/data/fakes/fake_reading_repository.dart';
import 'package:yeobaek/data/fakes/fake_store.dart';
import 'package:yeobaek/data/models/chat_message.dart';
import 'package:yeobaek/data/models/reading.dart';
import 'package:yeobaek/data/repositories.dart';
import 'package:yeobaek/features/chat/chat_screen.dart';
import 'package:yeobaek/features/save/save_screen.dart';

Widget _app(String poemId) =>
    MaterialApp(theme: buildAppTheme(), home: ChatScreen(poemId: poemId));

/// 정리하기로 S06까지 넘어가는 것을 볼 때
Widget _routedApp(String poemId) => MaterialApp(
      theme: buildAppTheme(),
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: ChatScreen(poemId: poemId),
    );

/// 저장 · 읽기가 실패하는 저장소 (네트워크가 끊긴 것처럼). 플래그를 내리면 되살아난다
class _FlakyReadingRepository extends FakeReadingRepository {
  _FlakyReadingRepository(super.store);

  bool failSave = false;
  bool failFetch = false;
  int saveCalls = 0;

  @override
  Future<void> saveProgress(String userId, Reading reading) async {
    saveCalls++;
    if (failSave) throw Exception('network');
    return super.saveProgress(userId, reading);
  }

  @override
  Future<Reading?> fetchReading(String userId, String poemId) async {
    if (failFetch) throw Exception('network');
    return super.fetchReading(userId, poemId);
  }
}

Future<Reading?> _savedReading(String poemId) =>
    Repositories.reading.fetchReading(FakeData.myUserId, poemId);

/// 가짜 에이전트는 0.7초 뒤에 답한다
Future<void> _waitForReply(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

Future<void> _send(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump();
  await tester.tap(find.text(AppStrings.chatSendButton));
  await tester.pump();
}

void main() {
  setUp(() => Repositories.useFakes(signedInUserId: FakeData.myUserId));

  testWidgets('대화가 비어 있으면 첫 질문을 받는다', (tester) async {
    await tester.pumpWidget(_app('bomgoyangi'));
    await tester.pump(); // 저장소에서 불러온 뒤에 요청을 보낸다
    expect(find.text(AppStrings.chatResponding), findsOneWidget);

    await _waitForReply(tester);
    expect(find.text(AppStrings.chatResponding), findsNothing);
    expect(find.text(openingFallbackQuestion('')), findsOneWidget);
  });

  testWidgets('보내면 답을 기다리는 동안 입력이 잠기고 중단 버튼이 나온다', (tester) async {
    await tester.pumpWidget(_app('seosi'));
    await tester.pumpAndSettle();

    await _send(tester, "'하늘을 보며'라는 구절 때문이에요");
    expect(find.text(AppStrings.chatStopButton), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);

    await _waitForReply(tester);
    expect(find.text(AppStrings.chatSendButton), findsOneWidget);
    expect(find.textContaining("'하늘'이 나오는 건 1행"), findsOneWidget);
  });

  testWidgets('중단하면 답을 기다리지 않고 다시 입력할 수 있다', (tester) async {
    await tester.pumpWidget(_app('seosi'));
    await tester.pumpAndSettle();

    await _send(tester, '잘 모르겠어요');
    await tester.tap(find.text(AppStrings.chatStopButton));
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);

    await _waitForReply(tester); // 늦게 온 답은 버린다
    expect(find.text(fallbackQuestions['seosi']!.first), findsNothing);
  });

  testWidgets('한 번에 200자를 넘게 입력할 수 없다', (tester) async {
    await tester.pumpWidget(_app('seosi'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '가' * 250);
    await tester.pump();
    expect(find.text(AppStrings.charCount(200, 200)), findsOneWidget);
  });

  testWidgets('힌트를 누르면 관찰 질문이 시트로 뜬다', (tester) async {
    await tester.pumpWidget(_app('seosi'));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.chatHintButton));
    await tester.pump();
    expect(find.text(AppStrings.chatHintTitle), findsOneWidget);

    // 서시 시연 대화는 모델이 쓴 질문으로 끝나므로, 목록의 다음 질문이 아니라 그 질문에서 출발하는 힌트
    await _waitForReply(tester);
    expect(find.text(followUpHint), findsOneWidget);
    expect(find.text(fallbackQuestions['seosi']!.first), findsNothing);
  });

  testWidgets('대화를 저장소에 저장하고, 다른 화면이 쓴 첫 낱말은 그대로 둔다', (tester) async {
    // S04가 첫 낱말을 저장하고 넘어온 상태
    await Repositories.reading.saveProgress(
      FakeData.myUserId,
      const Reading(poemId: 'bomgoyangi', firstWord: '봄', markedLines: [2]),
    );
    await tester.pumpWidget(_app('bomgoyangi'));
    await tester.pump();
    await _waitForReply(tester);

    final saved = await _savedReading('bomgoyangi');
    expect(saved!.firstWord, '봄');
    expect(saved.markedLines, [2]);
    expect(saved.conversation.single.text, openingFallbackQuestion('봄'));

    await _send(tester, '고양이 얘기 같아요');
    await _waitForReply(tester);
    final afterReply = await _savedReading('bomgoyangi');
    expect(afterReply!.conversation, hasLength(3));
    expect(afterReply.conversation[1].text, '고양이 얘기 같아요');
    expect(afterReply.firstWord, '봄');
  });

  testWidgets('저장된 대화를 불러와 이어 간다', (tester) async {
    await Repositories.reading.saveProgress(
      FakeData.myUserId,
      const Reading(
        poemId: 'bomgoyangi',
        conversation: [
          ChatMessage(role: ChatRole.assistant, text: '어느 행에서 멈췄나요?'),
          ChatMessage(role: ChatRole.user, text: '고양이 털 부분이요'),
        ],
        evidenceLines: [1],
      ),
    );
    await tester.pumpWidget(_app('bomgoyangi'));
    await tester.pumpAndSettle();

    expect(find.text('고양이 털 부분이요'), findsOneWidget);
    expect(find.text(AppStrings.chatResponding), findsNothing); // 첫 질문을 다시 받지 않는다
  });
  testWidgets('힌트를 기다리는 동안 무엇을 하는지 보인다 — 진행 막대만 있으면 멈춘 것 같았다', (tester) async {
    await tester.pumpWidget(_app('seosi'));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.chatHintButton));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text(AppStrings.chatHintWaiting), findsOneWidget);

    await _waitForReply(tester);
    expect(find.text(AppStrings.chatHintWaiting), findsNothing);
  });

  group('저장 · 불러오기가 실패할 때 — 조용히 넘어가지 않는다', () {
    late _FlakyReadingRepository flaky;
    setUp(() => Repositories.reading = flaky = _FlakyReadingRepository(FakeStore()));

    testWidgets('저장하지 못하면 알리고, 다음 말을 보낼 때 대화 전체를 다시 저장한다', (tester) async {
      flaky.failSave = true;
      await tester.pumpWidget(_app('bomgoyangi'));
      await _waitForReply(tester); // 첫 질문 → 저장 실패
      expect(find.text(AppStrings.chatSaveFailed), findsOneWidget);

      flaky.failSave = false;
      await _send(tester, '고양이 털이요');
      await _waitForReply(tester);
      final saved = await _savedReading('bomgoyangi');
      // 저장에 실패했던 첫 질문까지 함께 저장됐다
      expect(saved!.conversation, hasLength(3));
      expect(saved.conversation[1].text, '고양이 털이요');
      expect(find.text(AppStrings.chatSaveFailed), findsNothing); // 저장되면 안내도 걷힌다
    });

    testWidgets('저장이 계속 안 되면 정리로 넘어가지 않고 알린다 — 되살아나면 넘어간다', (tester) async {
      flaky.failSave = true;
      await tester.pumpWidget(_routedApp('bomgoyangi'));
      await _waitForReply(tester);

      await tester.tap(find.text(AppStrings.chatSummarizeButton));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.chatSaveBlocked), findsOneWidget);
      expect(find.byType(SaveScreen), findsNothing); // 옛 대화로 초안을 만들지 않게

      flaky.failSave = false;
      await tester.tap(find.text(AppStrings.chatSummarizeButton));
      await tester.pumpAndSettle();
      expect(find.byType(SaveScreen), findsOneWidget);
      expect((await _savedReading('bomgoyangi'))!.conversation, hasLength(1));
    });

    testWidgets('읽기 기록을 못 불러오면 대화를 시작하지 않고 다시 시도를 보인다', (tester) async {
      flaky.failFetch = true;
      await tester.pumpWidget(_app('bomgoyangi'));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.noticeUnavailable), findsOneWidget);
      expect(find.byType(TextField), findsNothing); // 저장되지 않을 대화를 시작하지 않는다
      expect(flaky.saveCalls, 0);

      flaky.failFetch = false;
      await tester.tap(find.text(AppStrings.noticeUnavailableAction));
      await _waitForReply(tester);
      expect(find.text(AppStrings.noticeUnavailable), findsNothing);
      expect(find.byType(TextField), findsOneWidget);
      expect((await _savedReading('bomgoyangi'))!.conversation, hasLength(1));
    });
  });
}
