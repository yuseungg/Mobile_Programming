// 주인: C — 진짜 프로필 저장소
// Firestore: users/{userId} · nicknames/{nickname}

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_profile.dart';
import '../reading_day.dart';
import '../repositories/user_repository.dart';
import 'converters.dart';

class FirestoreUserRepository implements UserRepository {
  FirestoreUserRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// 닉네임 뒤에 붙이는 숫자를 몇까지 시도할지. 넘으면 오류.
  static const _maxNicknameSuffix = 50;

  DocumentReference<Map<String, dynamic>> _user(String userId) =>
      _db.collection('users').doc(userId);

  DocumentReference<Map<String, dynamic>> _nickname(String nickname) =>
      _db.collection('nicknames').doc(nickname);

  @override
  Future<bool> hasProfile(String userId) async =>
      (await _user(userId).get()).exists;

  @override
  Future<String> createProfile(String userId, String nickname) {
    return _db.runTransaction((tx) async {
      // 이미 프로필이 있으면 그 닉네임을 그대로 쓴다 (두 번 눌러도 안전)
      final existing = await tx.get(_user(userId));
      if (existing.exists) {
        return existing.data()!['nickname'] as String;
      }

      // 비어 있는 닉네임을 찾는다: 조용한 별 → 조용한 별 2 → 조용한 별 3 …
      String? confirmed;
      for (var n = 1; n <= _maxNicknameSuffix; n++) {
        final candidate = n == 1 ? nickname : '$nickname $n';
        final taken = await tx.get(_nickname(candidate));
        if (!taken.exists) {
          confirmed = candidate;
          break;
        }
      }
      if (confirmed == null) {
        throw StateError('no free nickname for: $nickname');
      }

      tx.set(_nickname(confirmed), {'userId': userId});
      tx.set(_user(userId), newUserProfileDoc(confirmed));
      return confirmed;
    });
  }

  @override
  Future<UserProfile> fetchProfile(String userId) async {
    final snap = await _user(userId).get();
    final data = snap.data();
    if (data == null) throw StateError('no profile: $userId');
    return userProfileFromDoc(userId, data);
  }

  @override
  Stream<UserProfile> watchProfile(String userId) => _user(userId)
      .snapshots()
      .where((snap) => snap.exists)
      .map((snap) => userProfileFromDoc(userId, snap.data()!));

  @override
  Future<void> countReadingDay(String userId) async {
    final profile = await fetchProfile(userId);
    // 기기 시각으로 먼저 걸러 쓰기를 줄인다. 진짜 판정은 보안 규칙이 서버 시각으로 한다.
    if (isSameReadingDay(profile.lastCountedDate, DateTime.now())) return;
    try {
      await _user(userId).update({
        'totalReadingDays': FieldValue.increment(1),
        'lastCountedDate': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      // 서버 기준으로 이미 오늘 셌으면 규칙이 막는다 — 정상
      if (e.code != 'permission-denied') rethrow;
    }
  }
}
