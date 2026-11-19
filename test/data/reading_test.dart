// C — Reading.impressiveLine: 멈춘 행에 없으면 null (PR #27 리뷰에서 나온 해제 버그)
import 'package:flutter_test/flutter_test.dart';
import 'package:yeobaek/data/fakes/fake_data.dart';
import 'package:yeobaek/data/firestore/converters.dart';
import 'package:yeobaek/data/models/reading.dart';
import 'package:yeobaek/data/repositories.dart';

void main() {
  const reading = Reading(
    poemId: 'seosi',
    markedLines: [3, 6],
    impressiveLine: 6,
    isSaved: true,
  );

  test('멈춘 행 안에 있으면 그대로 돌려준다', () {
    expect(reading.impressiveLine, 6);
    expect(readingToDoc(reading)['impressiveLine'], 6);
  });

  test('그 행의 멈춤을 해제하면 null이 되고, 문서에는 키가 없다', () {
    final unmarked = reading.copyWith(markedLines: [3]);

    expect(unmarked.impressiveLine, isNull);
    // 보안 규칙: 키가 있으면 markedLines 안이어야 한다 → 키 자체가 없어야 통과
    expect(readingToDoc(unmarked).containsKey('impressiveLine'), isFalse);
  });

  test('다른 행을 해제하면 그대로 남는다', () {
    expect(reading.copyWith(markedLines: [6]).impressiveLine, 6);
  });

  test('copyWith: 새로 고르면 바뀌고, clearImpressiveLine이면 지워진다', () {
    expect(reading.copyWith(impressiveLine: 3).impressiveLine, 3);
    expect(reading.copyWith(clearImpressiveLine: true).impressiveLine, isNull);
    // 다른 필드만 바꾸면 그대로
    expect(reading.copyWith(interpretation: '해석').impressiveLine, 6);
  });

  test('저장소: S04에서 고른 행의 멈춤을 해제하면 고른 행도 사라진다', () async {
    Repositories.useFakes(signedInUserId: FakeData.myUserId);
    const userId = 'u1';
    await Repositories.reading.saveProgress(userId, reading);

    await Repositories.reading
        .setMarkedLine(userId, 'seosi', 6, isMarked: false);

    final after = await Repositories.reading.fetchReading(userId, 'seosi');
    expect(after!.markedLines, [3]);
    expect(after.impressiveLine, isNull);

    // 다시 멈춰도 되살아나지 않는다 (Firestore에서는 이미 지워졌다)
    await Repositories.reading
        .setMarkedLine(userId, 'seosi', 6, isMarked: true);
    final again = await Repositories.reading.fetchReading(userId, 'seosi');
    expect(again!.markedLines, [3, 6]);
    expect(again.impressiveLine, isNull);
  });
}
