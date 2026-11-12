// 주인: C — 계정 (F1 · S01 S02)
// 구현: fakes/fake_auth_repository.dart · firestore/firebase_auth_repository.dart

/// 로그인 · 가입이 실패한 이유. 화면은 이 값을 보고 AppStrings의 문구를 고른다.
enum AuthFailureReason {
  invalidCredentials, // 이메일이나 비밀번호가 맞지 않음
  emailAlreadyInUse, // 이미 가입된 이메일
  notGmail, // gmail.com 계정이 아님 (구글 로그인 포함)
  cancelled, // 사용자가 구글 로그인 창을 닫음
  network, // 네트워크 문제
  unknown,
}

class AuthFailure implements Exception {
  const AuthFailure(this.reason);
  final AuthFailureReason reason;

  @override
  String toString() => 'AuthFailure($reason)';
}

abstract interface class AuthRepository {
  /// 로그인한 사용자의 uid. 로그아웃 상태면 null.
  String? get currentUserId;

  /// 로그인 상태가 바뀔 때마다 uid(또는 null)를 내보낸다. 라우터 분기에 쓴다.
  Stream<String?> userIdChanges();

  /// 실패하면 [AuthFailure]를 던진다. 성공하면 uid.
  Future<String> signInWithEmail(String email, String password);

  /// 계정만 만든다. 프로필(닉네임)은 [UserRepository.createProfile]로 따로 만든다.
  Future<String> signUpWithEmail(String email, String password);

  /// gmail.com 계정이 아니면 로그아웃시키고 [AuthFailureReason.notGmail]을 던진다.
  /// 처음 로그인한 사람인지는 [UserRepository.hasProfile]로 확인한다.
  Future<String> signInWithGoogle();

  Future<void> signOut();
}
