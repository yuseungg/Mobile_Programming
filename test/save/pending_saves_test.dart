// 주인: B — 저장 실패 보관분 다시 저장 (lib/features/save/pending_saves.dart)
//
// 홈은 initState에서 retryPendingSaves()를 띄워 두고 기다리지 않는다. 그래서
// 재시도가 네트워크를 기다리는 사이에 사람이 S06까지 가서 저장하고, 또 실패해
// 보관하는 일이 실제로 생긴다. 그때 재시도가 목록을 통째로 덮어쓰면 방금 보관한
// 해석이 사라진다 — 저장은 잠금 해제 · 뱃지를 받는 자리라 날아가면 안 된다.
//
// 아래 테스트들은 그 사이 들어온 보관분이 남는지만 본다. 시간을 Completer로
// 잡아 두므로 실제 지연에 기대지 않는다.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeobaek/data/fakes/fake_data.dart';
import 'package:yeobaek/data/fakes/fake_reading_repository.dart';
import 'package:yeobaek/data/fakes/fake_store.dart';
import 'package:yeobaek/data/models/reading.dart';
import 'package:yeobaek/data/repositories.dart';
import 'package:yeobaek/features/save/pending_saves.dart';

/// fetchReading이 [gate]가 풀릴 때까지 멈춘다 — 오프라인에서 늦게 실패하는 상황.
class _SlowReadingRepository extends FakeReadingRepository {
  _SlowReadingRepository(super.store, this.gate);

  final Completer<void> gate;

  @override
  Future<Reading?> fetchReading(String userId, String poemId) async {
    await gate.future;
    return super.fetchReading(userId, poemId);
  }
}

/// 다시 저장해도 또 실패하는 저장소
class _StillFailingReadingRepository extends FakeReadingRepository {
  _StillFailingReadingRepository(super.store);

  @override
  Future<String?> saveInterpretation(
    String userId,
    Reading reading, {
    required String? summary,
  }) async {
    throw Exception('network');
  }
}

void main() {
  final me = FakeData.myUserId;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Repositories.useFakes();
  });

  Future<void> keep(String poemId, String interpretation) {
    return keepPendingSave(
      me,
      Reading(poemId: poemId, interpretation: interpretation),
      null,
    );
  }

  test('재시도가 도는 사이에 보관한 해석이 남는다', () async {
    final gate = Completer<void>();
    Repositories.reading = _SlowReadingRepository(FakeStore(), gate);

    await keep('seosi', '서시 보관분');

    // 홈이 열려 재시도가 시작되고 fetchReading에서 멈춘다
    final retry = retryPendingSaves();
    await Future<void>.delayed(Duration.zero);

    // 그 사이 사람이 S06에서 다른 시를 저장했는데 또 실패했다
    await keep('jindallae', '진달래꽃 보관분');

    gate.complete();
    await retry;

    final survived = await findPendingSave(me, 'jindallae');
    expect(survived, isNotNull);
    expect(survived!.interpretation, '진달래꽃 보관분');
  });

  test('재시도가 도는 사이에 같은 시를 또 보관하면 새 보관분이 남는다', () async {
    final gate = Completer<void>();
    Repositories.reading = _SlowReadingRepository(FakeStore(), gate);

    await keep('seosi', '처음 보관분');

    final retry = retryPendingSaves();
    await Future<void>.delayed(Duration.zero);

    // 같은 시를 고쳐 다시 저장 → 또 실패 → 보관분이 새 내용으로 바뀐다
    await keep('seosi', '고친 보관분');

    gate.complete();
    await retry;

    // 재시도가 성공시킨 것은 「처음 보관분」이다. 새 것을 그것과 함께 지우면 안 된다
    final survived = await findPendingSave(me, 'seosi');
    expect(survived, isNotNull);
    expect(survived!.interpretation, '고친 보관분');
  });

  test('재시도가 도는 사이에 S06에서 새 해석이 저장되면 옛 보관분으로 덮지 않는다', () async {
    final gate = Completer<void>();
    Repositories.reading = _SlowReadingRepository(FakeStore(), gate);

    await keep('seosi', '옛 해석');

    final retry = retryPendingSaves();
    await Future<void>.delayed(Duration.zero);

    // 그 사이 S06에서 새 해석 저장에 성공 → 보관분은 지움
    await Repositories.reading.saveInterpretation(
      me,
      const Reading(poemId: 'seosi', interpretation: '새 해석'),
      summary: null,
    );
    await removePendingSave(me, 'seosi');

    gate.complete();
    final saved = await retry;

    expect(saved, 0); // 건너뜀
    expect(
      (await Repositories.reading.fetchReading(me, 'seosi'))?.interpretation,
      '새 해석',
    );
  });

  test('다시 저장에 성공한 보관분은 지운다', () async {
    await keep('seosi', '서시 보관분');

    final saved = await retryPendingSaves();

    expect(saved, 1);
    expect(await findPendingSave(me, 'seosi'), isNull);
    expect(
      (await Repositories.reading.fetchReading(me, 'seosi'))?.interpretation,
      '서시 보관분',
    );
  });

  test('또 실패하면 보관분을 남긴다', () async {
    Repositories.reading = _StillFailingReadingRepository(FakeStore());
    await keep('seosi', '서시 보관분');

    final saved = await retryPendingSaves();

    expect(saved, 0);
    expect(await findPendingSave(me, 'seosi'), isNotNull);
  });

  test('다른 계정의 보관분은 건드리지 않는다', () async {
    await keepPendingSave(
      'someone_else',
      const Reading(poemId: 'jindallae', interpretation: '남의 보관분'),
      null,
    );
    await keep('seosi', '내 보관분');

    final saved = await retryPendingSaves();

    expect(saved, 1);
    expect(await findPendingSave(me, 'seosi'), isNull);
    expect(await findPendingSave('someone_else', 'jindallae'), isNotNull);
  });
}
