// 주인: C — 가짜 저장소들이 함께 쓰는 메모리 속 '가짜 Firestore'.
//
// 저장 한 번에 읽기 · 뱃지 · 공개 대화가 같이 바뀌므로(한 트랜잭션),
// 저장소마다 따로 들고 있지 않고 여기 한 곳에 모아둔다.
// 처음 값은 FakeData를 복사한 것이다. FakeData 자체는 바뀌지 않는다.

import 'dart:async';

import '../models/public_conversation.dart';
import '../models/reading.dart';
import '../models/user_profile.dart';
import 'fake_data.dart';

class FakeStore {
  FakeStore({DateTime Function()? now}) : now = now ?? DateTime.now;

  /// '서버 시간' 대신. 테스트에서 바꿔 끼운다.
  final DateTime Function() now;

  /// users/{userId}
  final profiles = Map<String, UserProfile>.of(FakeData.profiles);

  /// users/{userId}/readings/{poemId}
  final readings = <String, Map<String, Reading>>{
    FakeData.myUserId: Map<String, Reading>.of(FakeData.myReadings),
  };

  /// lineStops/{poemId} — 행 번호(1부터) → stopCount
  final stopCounts = {
    for (final entry in FakeData.stopCounts.entries)
      entry.key: Map<int, int>.of(entry.value),
  };

  /// publicConversations/{conversationId}
  final conversations = <String, PublicConversation>{
    for (final c in FakeData.publicConversations) c.conversationId: c,
  };

  /// publicConversations/{conversationId}/empathies/{userId}
  final empathies = <String, Set<String>>{};

  final _profileChanges = StreamController<UserProfile>.broadcast();

  Stream<UserProfile> get profileChanges => _profileChanges.stream;

  void putProfile(UserProfile profile) {
    profiles[profile.userId] = profile;
    _profileChanges.add(profile);
  }

  Map<String, Reading> readingsOf(String userId) =>
      readings.putIfAbsent(userId, () => {});
}
