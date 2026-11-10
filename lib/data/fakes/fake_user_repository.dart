// 주인: C — 가짜 프로필 저장소.

import '../models/user_profile.dart';
import '../reading_day.dart';
import '../repositories/user_repository.dart';
import 'fake_store.dart';

class FakeUserRepository implements UserRepository {
  FakeUserRepository(this._store);

  final FakeStore _store;

  @override
  Future<bool> hasProfile(String userId) async =>
      _store.profiles.containsKey(userId);

  @override
  Future<String> createProfile(String userId, String nickname) async {
    final taken = _store.profiles.values.map((p) => p.nickname).toSet();
    var confirmed = nickname;
    for (var n = 2; taken.contains(confirmed); n++) {
      confirmed = '$nickname $n';
    }
    _store.putProfile(UserProfile(
      userId: userId,
      nickname: confirmed,
      totalReadingDays: 0,
      lastCountedDate: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      badgeIds: const [],
    ));
    return confirmed;
  }

  @override
  Future<UserProfile> fetchProfile(String userId) async {
    final profile = _store.profiles[userId];
    if (profile == null) throw StateError('no profile: $userId');
    return profile;
  }

  @override
  Stream<UserProfile> watchProfile(String userId) async* {
    final profile = _store.profiles[userId];
    if (profile != null) yield profile;
    yield* _store.profileChanges.where((p) => p.userId == userId);
  }

  @override
  Future<void> countReadingDay(String userId) async {
    final profile = await fetchProfile(userId);
    final now = _store.now();
    if (isSameReadingDay(profile.lastCountedDate, now)) return;
    _store.putProfile(profile.copyWith(
      totalReadingDays: profile.totalReadingDays + 1,
      lastCountedDate: now,
    ));
  }
}
