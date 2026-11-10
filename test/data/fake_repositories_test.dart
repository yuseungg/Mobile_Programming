import 'package:flutter_test/flutter_test.dart';
import 'package:yeobaek/data/fakes/fake_auth_repository.dart';
import 'package:yeobaek/data/fakes/fake_data.dart';
import 'package:yeobaek/data/fakes/fake_public_conversation_repository.dart';
import 'package:yeobaek/data/fakes/fake_reading_repository.dart';
import 'package:yeobaek/data/fakes/fake_store.dart';
import 'package:yeobaek/data/fakes/fake_user_repository.dart';
import 'package:yeobaek/data/models/reading.dart';
import 'package:yeobaek/data/nickname_words.dart';
import 'package:yeobaek/data/reading_day.dart';
import 'package:yeobaek/data/repositories.dart';

void main() {
  group('하루 경계 (한국 시간)', () {
    test('UTC 14:59와 15:00은 한국 시간으로 다른 날이다', () {
      final before = DateTime.utc(2026, 11, 10, 14, 59); // 한국 23:59
      final after = DateTime.utc(2026, 11, 10, 15, 0); // 한국 다음 날 0:00
      expect(isSameReadingDay(before, after), isFalse);
    });

    test('한국 오전 8시와 오전 10시는 같은 날이다 (UTC 날짜는 달라도)', () {
      final morning = DateTime.utc(2026, 11, 9, 23); // 한국 11/10 8:00
      final later = DateTime.utc(2026, 11, 10, 1); // 한국 11/10 10:00
      expect(isSameReadingDay(morning, later), isTrue);
    });
  });

  group('누적일수', () {
    test('같은 날 두 번 들어가도 1일, 다음 날 +1', () async {
      var now = DateTime.utc(2026, 11, 10, 3);
      final users = FakeUserRepository(FakeStore(now: () => now));
      await users.createProfile('u1', '조용한 별');

      await users.countReadingDay('u1');
      await users.countReadingDay('u1');
      expect((await users.fetchProfile('u1')).totalReadingDays, 1);

      now = now.add(const Duration(days: 1));
      await users.countReadingDay('u1');
      expect((await users.fetchProfile('u1')).totalReadingDays, 2);
    });
  });

  group('닉네임', () {
    test('겹치면 숫자를 붙여 확정한다', () async {
      final users = FakeUserRepository(FakeStore());
      final taken = FakeData.profiles[FakeData.myUserId]!.nickname;
      final confirmed = await users.createProfile('new_user', taken);
      expect(confirmed, '$taken 2');
    });

    test('새로고침하면 직전과 다른 닉네임이 나온다', () {
      for (var i = 0; i < 50; i++) {
        final first = drawNickname();
        expect(drawNickname(except: first), isNot(first));
      }
    });
  });

  group('최종 저장 (읽기 · 뱃지 · 공개 대화를 한 번에)', () {
    late FakeStore store;
    late FakeUserRepository users;
    late FakeReadingRepository readings;

    setUp(() async {
      store = FakeStore();
      users = FakeUserRepository(store);
      readings = FakeReadingRepository(store);
      await users.createProfile('u1', '먼 바람');
    });

    test('저장하면 뱃지를 받고, 다시 저장해도 뱃지는 하나다', () async {
      const reading = Reading(poemId: 'seosi', interpretation: '해석');
      await readings.saveInterpretation('u1', reading);
      await readings.saveInterpretation('u1', reading);

      expect((await users.fetchProfile('u1')).badgeIds, ['seosi']);
      expect((await readings.fetchReading('u1', 'seosi'))!.isSaved, isTrue);
    });

    test('공개를 고르면 공개 대화가 하나 생기고, 다시 저장해도 늘지 않는다', () async {
      const reading = Reading(
        poemId: 'seosi',
        firstWord: '부끄럼',
        interpretation: '해석',
        evidenceLines: [2, 4],
        isPublic: true,
      );
      final before = store.conversations.length;

      final id = await readings.saveInterpretation('u1', reading,
          summary: '요약');
      expect(id, isNotNull);
      final created = store.conversations[id]!;
      expect(created.userId, 'u1');
      expect(created.summary, '요약');
      expect(created.evidenceLines, [2, 4]);
      expect(created.empathyCount, 0);

      expect(await readings.saveInterpretation('u1', reading), isNull);
      expect(store.conversations.length, before + 1);
    });

    test('공개를 고르지 않거나 해석이 비어 있으면 공개 대화를 만들지 않는다', () async {
      expect(
        await readings.saveInterpretation(
            'u1', const Reading(poemId: 'seosi', interpretation: '해석')),
        isNull,
      );
      expect(
        await readings.saveInterpretation(
            'u1', const Reading(poemId: 'jindallae', isPublic: true)),
        isNull,
      );
    });

    test('대조를 연 뒤에는 해석을 고칠 수 없다', () async {
      const reading = Reading(poemId: 'bomgoyangi', interpretation: '처음 해석');
      await readings.saveInterpretation('u1', reading);
      await readings.openComparison('u1', 'bomgoyangi');

      expect(
        () => readings.saveInterpretation(
          'u1',
          reading.copyWith(interpretation: '고친 해석'),
        ),
        throwsA(isA<InterpretationLockedException>()),
      );
    });
  });

  group('내 읽기', () {
    test('저장 전에는 대조 열람이 기록되지 않는다', () async {
      final readings = FakeReadingRepository(FakeStore());
      await readings.saveProgress('u1', const Reading(poemId: 'bomgoyangi'));
      await readings.openComparison('u1', 'bomgoyangi');
      final saved = await readings.fetchReading('u1', 'bomgoyangi');
      expect(saved!.hasOpenedComparison, isFalse);
    });

    test('멈춘 행을 켜고 끄면 집계도 같이 바뀐다 (행 번호는 1부터)', () async {
      final readings = FakeReadingRepository(FakeStore());
      final before = (await readings.fetchStopCounts('seosi'))[6] ?? 0;

      await readings.setMarkedLine('u1', 'seosi', 6, isMarked: true);
      await readings.setMarkedLine('u1', 'seosi', 6, isMarked: true); // 두 번 눌러도 +1
      expect((await readings.fetchStopCounts('seosi'))[6], before + 1);
      expect((await readings.fetchReading('u1', 'seosi'))!.markedLines, [6]);

      await readings.setMarkedLine('u1', 'seosi', 6, isMarked: false);
      expect((await readings.fetchStopCounts('seosi'))[6] ?? 0, before);
    });

    test('기록 지우기는 대화만 비우고 해석은 남긴다', () async {
      final readings = FakeReadingRepository(FakeStore());
      await readings.clearConversations(FakeData.myUserId);
      final seosi = await readings.fetchReading(FakeData.myUserId, 'seosi');
      expect(seosi!.conversation, isEmpty);
      expect(seosi.interpretation, isNotEmpty);
      expect(seosi.isSaved, isTrue);
    });
  });

  group('공개 대화', () {
    late FakePublicConversationRepository conversations;

    setUp(() {
      final auth = FakeAuthRepository(signedInUserId: FakeData.myUserId);
      conversations = FakePublicConversationRepository(FakeStore(), auth);
    });

    test('해석을 저장한 시는 열리고, 저장하지 않은 시는 잠긴다', () async {
      // 가짜 데이터에서 서시는 저장됨, 진달래꽃은 저장 전
      expect(await conversations.fetchForPoem('seosi'), isNotEmpty);
      expect(
        () => conversations.fetchForPoem('jindallae'),
        throwsA(isA<ConversationsLockedException>()),
      );
    });

    test('목록은 최신순이다 (공감 수로 정렬하지 않는다)', () async {
      final list = await conversations.fetchForPoem('seosi');
      for (var i = 1; i < list.length; i++) {
        expect(list[i - 1].createdAt.isAfter(list[i].createdAt), isTrue);
      }
    });

    test('공감은 한 사람당 한 번, 끄면 줄어든다', () async {
      final before = (await conversations.fetchById('post_1')).empathyCount;
      await conversations.setEmpathy('post_1', 'u1', hasEmpathized: true);
      await conversations.setEmpathy('post_1', 'u1', hasEmpathized: true);
      expect((await conversations.fetchById('post_1')).empathyCount,
          before + 1);
      expect(await conversations.hasEmpathized('post_1', 'u1'), isTrue);

      await conversations.setEmpathy('post_1', 'u1', hasEmpathized: false);
      expect((await conversations.fetchById('post_1')).empathyCount, before);
    });
  });

  group('계정', () {
    test('gmail이 아니면 가입할 수 없다', () async {
      final auth = FakeAuthRepository();
      expect(
        () => auth.signUpWithEmail('someone@cau.ac.kr', 'abc123'),
        throwsA(isA<AuthFailure>().having(
            (f) => f.reason, 'reason', AuthFailureReason.notGmail)),
      );
    });

    test('데모 계정으로 로그인하면 상태가 바뀐다', () async {
      final auth = FakeAuthRepository();
      expect(auth.currentUserId, isNull);
      await auth.signInWithEmail(
          FakeAuthRepository.demoEmail, FakeAuthRepository.demoPassword);
      expect(auth.currentUserId, FakeData.myUserId);
      await auth.signOut();
      expect(auth.currentUserId, isNull);
    });
  });
}
