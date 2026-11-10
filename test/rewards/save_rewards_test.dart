// 주인: D — lib/rewards/save_rewards.dart 단위 테스트
// 기준: docs/여백-기획서최종.md 6장(뱃지는 시마다 한 번) · 7장(시각은 서버 시간)

import 'package:flutter_test/flutter_test.dart';
import 'package:yeobaek/data/models/reading.dart';
import 'package:yeobaek/rewards/save_rewards.dart';

Reading savedReading({
  String poemId = 'seosi',
  String interpretation = '내 해석',
  bool isPublic = false,
  bool isSaved = true,
  List<int> evidenceLines = const [6],
  String firstWord = '다짐',
}) {
  return Reading(
    poemId: poemId,
    firstWord: firstWord,
    evidenceLines: evidenceLines,
    interpretation: interpretation,
    isSaved: isSaved,
    isPublic: isPublic,
  );
}

void main() {
  final createdAt = DateTime.utc(2026, 11, 10, 12, 0);

  group('badgeToAward — 시마다 한 번', () {
    test('처음 저장하면 그 시의 뱃지를 준다', () {
      expect(
        badgeToAward(reading: savedReading(), ownedBadgeIds: const []),
        'seosi',
      );
    });

    test('이미 가진 시면 주지 않는다', () {
      expect(
        badgeToAward(reading: savedReading(), ownedBadgeIds: const ['seosi']),
        isNull,
      );
    });

    test('다른 시의 뱃지를 가지고 있어도 새 시는 받는다', () {
      expect(
        badgeToAward(
          reading: savedReading(poemId: 'jindallae'),
          ownedBadgeIds: const ['seosi'],
        ),
        'jindallae',
      );
    });

    test('저장되지 않은 읽기에는 주지 않는다', () {
      expect(
        badgeToAward(
          reading: savedReading(isSaved: false),
          ownedBadgeIds: const [],
        ),
        isNull,
      );
    });
  });

  group('publicConversationToCreate', () {
    test('공개가 꺼져 있으면 만들지 않는다 (기본 꺼짐)', () {
      expect(
        publicConversationToCreate(
          conversationId: 'c1',
          userId: 'u1',
          reading: savedReading(isPublic: false),
          summary: '요약',
          createdAt: createdAt,
        ),
        isNull,
      );
    });

    test('저장되지 않은 읽기는 공개하지 않는다', () {
      expect(
        publicConversationToCreate(
          conversationId: 'c1',
          userId: 'u1',
          reading: savedReading(isPublic: true, isSaved: false),
          summary: '요약',
          createdAt: createdAt,
        ),
        isNull,
      );
    });

    test('해석이 공백뿐이면 공개하지 않는다', () {
      expect(
        publicConversationToCreate(
          conversationId: 'c1',
          userId: 'u1',
          reading: savedReading(isPublic: true, interpretation: '   '),
          summary: '요약',
          createdAt: createdAt,
        ),
        isNull,
      );
    });

    test('공개면 문서를 만들고, 공감 수는 0에서 시작한다', () {
      final doc = publicConversationToCreate(
        conversationId: 'c1',
        userId: 'u1',
        reading: savedReading(isPublic: true),
        summary: '대화 요약',
        createdAt: createdAt,
      )!;
      expect(doc.conversationId, 'c1');
      expect(doc.userId, 'u1');
      expect(doc.poemId, 'seosi');
      expect(doc.firstWord, '다짐');
      expect(doc.summary, '대화 요약');
      expect(doc.interpretation, '내 해석');
      expect(doc.empathyCount, 0);
      expect(doc.evidenceLines, [6]);
      expect(doc.createdAt, createdAt);
    });

    test('시각은 넣어 준 값을 그대로 쓴다 — 함수가 시계를 읽지 않는다', () {
      // 기획서 7장: 날짜는 기기 시간이 아니라 서버 시간 기준으로 센다.
      final past = DateTime.utc(2020, 1, 1);
      final doc = publicConversationToCreate(
        conversationId: 'c1',
        userId: 'u1',
        reading: savedReading(isPublic: true),
        summary: '요약',
        createdAt: past,
      )!;
      expect(doc.createdAt, past);
    });

    test('근거 행이 없어도 만든다', () {
      final doc = publicConversationToCreate(
        conversationId: 'c1',
        userId: 'u1',
        reading: savedReading(isPublic: true, evidenceLines: const []),
        summary: '요약',
        createdAt: createdAt,
      )!;
      expect(doc.evidenceLines, isEmpty);
    });
  });
}
