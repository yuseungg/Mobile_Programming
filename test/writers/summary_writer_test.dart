// 주인: D — 공개 대화 요약 폴백 (기획서 F7 · 9장)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
  }) =>
      SummaryRequest(
        poemId: 'seosi',
        firstWord: firstWord,
        conversation: conversation,
        interpretation: '내 해석',
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

    test('항상 비어 있지 않다', () async {
      expect((await writer.write(request(firstWord: ''))).text.trim(),
          isNotEmpty);
    });
  });

  group('S09 — 요약이 비어 있으면 폴백으로 채운다', () {
    PublicConversation conversation(String summary) => PublicConversation(
          conversationId: 'c1',
          userId: 'user_1',
          poemId: 'seosi',
          firstWord: '다짐',
          summary: summary,
          interpretation: '남의 해석',
          empathyCount: 0,
          createdAt: DateTime.utc(2026, 11, 1),
        );

    Future<void> pump(WidgetTester tester, String summary) async {
      final source = StubReadingSource(
        conversations: [conversation(summary)],
        readings: const {'seosi': Reading(poemId: 'seosi', isSaved: true)},
      );
      await tester.pumpWidget(
        MaterialApp(
          home: CommunityDetailScreen(conversationId: 'c1', source: source),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('담긴 요약이 있으면 그것을 보여 준다', (tester) async {
      await pump(tester, '저장할 때 쓰인 요약');
      expect(find.text('저장할 때 쓰인 요약'), findsOneWidget);
    });

    testWidgets('비어 있으면 첫 낱말로 채운다', (tester) async {
      await pump(tester, '   ');
      expect(find.textContaining('다짐'), findsWidgets);
      expect(find.text('   '), findsNothing);
    });
  });
}
