// 주인: D — 공개 대화 요약 폴백 (기획서 F7 · 9장)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yeobaek/app/language.dart';
import 'package:yeobaek/data/models/chat_message.dart';
import 'package:yeobaek/data/models/public_conversation.dart';
import 'package:yeobaek/data/models/reading.dart';
import 'package:yeobaek/features/community/community_detail_screen.dart';
import 'package:yeobaek/writers/fake_summary_writer.dart';
import 'package:yeobaek/writers/summary_writer.dart';

import '../support/stub_reading_source.dart';

void main() {
  const writer = FakeSummaryWriter();

  SummaryRequest request({
    String firstWord = '다짐',
    List<ChatMessage> conversation = const [],
    AppLanguage language = AppLanguage.ko,
  }) =>
      SummaryRequest(
        poemId: 'seosi',
        firstWord: firstWord,
        conversation: conversation,
        interpretation: '내 해석',
        language: language,
      );

  group('FakeSummaryWriter — 사실만 적는다', () {
    test('첫 낱말을 그대로 싣는다', () async {
      final text = (await writer.write(request())).text;
      expect(text, contains('다짐'));
      expect((await writer.write(request())).isFallback, isTrue);
    });

    test('AI 질문 수를 센다', () async {
      final text = (await writer.write(request(conversation: const [
        ChatMessage(role: ChatRole.user, text: '내 말'),
        ChatMessage(role: ChatRole.assistant, text: '질문 1'),
        ChatMessage(role: ChatRole.assistant, text: '질문 2'),
      ]))).text;
      expect(text, contains('2개'));
    });

    test('대화가 없으면 질문 수를 말하지 않는다', () async {
      final text = (await writer.write(request())).text;
      expect(text, isNot(contains('개')));
    });

    test('대화 내용을 옮기지 않는다 — 남이 읽는 글이다', () async {
      final text = (await writer.write(request(conversation: const [
        ChatMessage(role: ChatRole.user, text: '비밀스러운 내 말'),
        ChatMessage(role: ChatRole.assistant, text: 'AI가 던진 질문'),
      ]))).text;
      expect(text, isNot(contains('비밀스러운')));
      expect(text, isNot(contains('AI가 던진')));
    });

    test('요청의 언어로 쓴다 — 화면이 한국어여도 영어 요청이면 영어', () async {
      expect(appLanguage.value, AppLanguage.ko);
      final english =
          (await writer.write(request(language: AppLanguage.en))).text;
      expect(english, 'A conversation that began with “다짐”.');
    });

    test('항상 비어 있지 않다', () async {
      expect((await writer.write(request(firstWord: ''))).text.trim(),
          isNotEmpty);
    });
  });

  group('S09 — 보는 사람의 언어로, 비어 있으면 폴백으로', () {
    PublicConversation conversation({required String ko, required String en}) =>
        PublicConversation(
          conversationId: 'c1',
          userId: 'user_1',
          poemId: 'seosi',
          firstWord: '다짐',
          summaryKo: ko,
          summaryEn: en,
          interpretation: '남의 해석',
          empathyCount: 0,
          createdAt: DateTime.utc(2026, 11, 1),
        );

    Future<void> pump(
      WidgetTester tester, {
      required String ko,
      required String en,
    }) async {
      final source = StubReadingSource(
        conversations: [conversation(ko: ko, en: en)],
        readings: const {'seosi': Reading(poemId: 'seosi', isSaved: true)},
      );
      await tester.pumpWidget(
        MaterialApp(
          home: CommunityDetailScreen(conversationId: 'c1', source: source),
        ),
      );
      await tester.pumpAndSettle();
    }

    /// KR / EN을 바꾼 것처럼 — 앱(YeobaekApp)은 바꿀 때 화면을 전부 다시 그린다
    Future<void> switchTo(WidgetTester tester, AppLanguage language) async {
      appLanguage.value = language;
      tester.element(find.byType(CommunityDetailScreen)).markNeedsBuild();
      await tester.pump();
    }

    tearDown(() => appLanguage.value = AppLanguage.ko);

    testWidgets('담긴 요약을 보는 사람의 언어로 보여 주고, 언어를 바꾸면 따라 바뀐다',
        (tester) async {
      await pump(tester, ko: '저장할 때 쓰인 요약', en: 'Summary written when saved');
      expect(find.text('저장할 때 쓰인 요약'), findsOneWidget);
      expect(find.text('Summary written when saved'), findsNothing);

      await switchTo(tester, AppLanguage.en);
      expect(find.text('Summary written when saved'), findsOneWidget);
      expect(find.text('저장할 때 쓰인 요약'), findsNothing);
    });

    testWidgets('비어 있으면 그 언어로 첫 낱말에서 채운다', (tester) async {
      await pump(tester, ko: '   ', en: '   ');
      expect(find.text('「다짐」에서 시작한 대화예요.'), findsOneWidget);
      expect(find.text('   '), findsNothing);

      await switchTo(tester, AppLanguage.en);
      expect(find.text('A conversation that began with “다짐”.'), findsOneWidget);
    });
  });
}
