import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yeobaek/data/firestore/converters.dart';
import 'package:yeobaek/data/firestore/firebase_config.dart';
import 'package:yeobaek/data/models/chat_message.dart';
import 'package:yeobaek/data/models/reading.dart';

void main() {
  group('읽기 문서 변환', () {
    test('보낸 그대로 돌아온다 (필드 이름은 네이밍규칙 5장)', () {
      const reading = Reading(
        poemId: 'seosi',
        firstWord: '부끄럼',
        markedLines: [2, 10],
        conversation: [
          ChatMessage(role: ChatRole.assistant, text: '어느 줄에서 멈췄나요?'),
          ChatMessage(role: ChatRole.user, text: '2행'),
        ],
        evidenceLines: [2],
        interpretation: '내 해석',
        isSaved: true,
        hasOpenedComparison: false,
        isPublic: true,
      );

      final doc = readingToDoc(reading);
      expect(
        doc.keys,
        unorderedEquals([
          'firstWord', 'markedLines', 'conversation', 'evidenceLines',
          'interpretation', 'isSaved', 'hasOpenedComparison', 'isPublic',
        ]),
      );

      final back = readingFromDoc('seosi', doc);
      expect(back.firstWord, '부끄럼');
      expect(back.markedLines, [2, 10]);
      expect(back.conversation.map((m) => m.role),
          [ChatRole.assistant, ChatRole.user]);
      expect(back.conversation.last.text, '2행');
      expect(back.evidenceLines, [2]);
      expect(back.isSaved, isTrue);
      expect(back.isPublic, isTrue);
    });

    test('빠진 필드는 기본값으로 읽는다', () {
      final back = readingFromDoc('seosi', {});
      expect(back.firstWord, '');
      expect(back.markedLines, isEmpty);
      expect(back.isSaved, isFalse);
    });
  });

  group('프로필 문서 변환', () {
    test('새 프로필은 0일 · 뱃지 없음 · 1970년부터', () {
      final doc = newUserProfileDoc('조용한 별');
      final profile = userProfileFromDoc('u1', doc);
      expect(profile.nickname, '조용한 별');
      expect(profile.totalReadingDays, 0);
      expect(profile.badgeIds, isEmpty);
      expect(profile.lastCountedDate.millisecondsSinceEpoch, 0);
    });

    test('서버 시각이 아직 안 찍힌 문서(null)도 읽힌다', () {
      final profile = userProfileFromDoc('u1', {
        'nickname': '먼 바람',
        'totalReadingDays': 3,
        'lastCountedDate': null,
        'badgeIds': ['seosi'],
      });
      expect(profile.totalReadingDays, 3);
      expect(profile.badgeIds, ['seosi']);
    });
  });

  group('공개 대화 문서 변환', () {
    test('Timestamp를 DateTime으로 읽는다', () {
      final createdAt = DateTime.utc(2026, 11, 12, 10);
      final conversation = publicConversationFromDoc('u1_seosi', {
        'userId': 'u1',
        'poemId': 'seosi',
        'firstWord': '부끄럼',
        'summary': '요약',
        'interpretation': '해석',
        'empathyCount': 4,
        'evidenceLines': [2, 10],
        'createdAt': Timestamp.fromDate(createdAt),
      });
      expect(conversation.conversationId, 'u1_seosi');
      expect(conversation.empathyCount, 4);
      expect(conversation.evidenceLines, [2, 10]);
      expect(conversation.createdAt.toUtc(), createdAt);
    });
  });

  group('멈춤 집계 변환', () {
    test('문자열 키를 행 번호로, 0 이하는 뺀다', () {
      expect(
        stopCountsFromDoc({
          'counts': {'2': 12, '4': 0, '6': 8, '10': -1},
        }),
        {2: 12, 6: 8},
      );
    });

    test('문서가 없으면 빈 집계', () {
      expect(stopCountsFromDoc(null), isEmpty);
    });
  });

  group('gmail 제한', () {
    test('gmail.com만 허용, 대소문자 · 앞뒤 공백 무시', () {
      expect(isAllowedEmail('someone@gmail.com'), isTrue);
      expect(isAllowedEmail('  Someone@Gmail.COM '), isTrue);
      expect(isAllowedEmail('someone@cau.ac.kr'), isFalse);
      expect(isAllowedEmail('someone@gmail.com.evil.kr'), isFalse);
    });
  });
}
