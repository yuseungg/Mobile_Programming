// 주인: C — 사용자 프로필 · 누적일수 · 뱃지 (F1 F8)
// Firestore: users/{userId} · nicknames/{nickname}
// 사용: C(S02 가입), B(S03 홈 · S04 누적일수), D(S12 프로필 · 뱃지)
// 뱃지 지급은 여기 없다 — ReadingRepository.saveInterpretation 안에서 함께 일어난다.

import '../models/user_profile.dart';

abstract interface class UserRepository {
  /// 프로필 문서가 있는가. 없으면 닉네임을 정하는 화면으로 보낸다
  /// (구글 첫 로그인, 또는 가입 도중 앱이 꺼진 경우).
  Future<bool> hasProfile(String userId);

  /// 닉네임을 예약하고 프로필을 만든다 (트랜잭션).
  /// 이미 쓰는 닉네임이면 뒤에 숫자를 붙여 비어 있는 것을 찾는다.
  /// 실제로 확정된 닉네임을 돌려준다.
  Future<String> createProfile(String userId, String nickname);

  Future<UserProfile> fetchProfile(String userId);

  /// S03 홈 문구처럼 값이 바뀌면 다시 그려야 하는 곳에 쓴다.
  Stream<UserProfile> watchProfile(String userId);

  /// B — S04 읽기에 들어갈 때 부른다.
  /// 한국 시간으로 오늘 이미 셌으면 아무 일도 하지 않는다. 날짜는 서버 시간 기준.
  Future<void> countReadingDay(String userId);
}
