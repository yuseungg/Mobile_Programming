// 주인: C — 진짜 계정 (Firebase Auth + google_sign_in 7)

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../repositories/auth_repository.dart';
import 'firebase_config.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
      : _auth = auth ?? FirebaseAuth.instance,
        _google = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _auth;
  final GoogleSignIn _google;
  Future<void>? _googleReady;

  /// google_sign_in 7은 authenticate 전에 initialize를 딱 한 번 불러야 한다.
  /// 실패하면 기억해 둔 것을 지워서, 다음에 누르면 다시 시도한다.
  Future<void> _ensureGoogleReady() async {
    final ready = _googleReady ??=
        _google.initialize(serverClientId: googleServerClientId);
    try {
      await ready;
    } catch (_) {
      _googleReady = null;
      rethrow;
    }
  }

  @override
  String? get currentUserId => _auth.currentUser?.uid;

  @override
  Stream<String?> userIdChanges() =>
      _auth.authStateChanges().map((user) => user?.uid);

  @override
  Future<String> signInWithEmail(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return result.user!.uid;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_reasonOf(e));
    }
  }

  @override
  Future<String> signUpWithEmail(String email, String password) async {
    if (!isAllowedEmail(email)) {
      throw const AuthFailure(AuthFailureReason.notGmail);
    }
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return result.user!.uid;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_reasonOf(e));
    }
  }

  @override
  Future<String> signInWithGoogle() async {
    final GoogleSignInAccount account;
    try {
      await _ensureGoogleReady();
      account = await _google.authenticate();
    } on GoogleSignInException catch (e) {
      throw AuthFailure(
        e.code == GoogleSignInExceptionCode.canceled
            ? AuthFailureReason.cancelled
            : AuthFailureReason.unknown,
      );
    }

    // gmail.com 계정만 받는다 — Firebase에 계정이 생기기 전에 거른다
    if (!isAllowedEmail(account.email)) {
      await _google.signOut();
      throw const AuthFailure(AuthFailureReason.notGmail);
    }

    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw const AuthFailure(AuthFailureReason.unknown);
    }
    try {
      final result = await _auth.signInWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );
      return result.user!.uid;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_reasonOf(e));
    }
  }

  @override
  Future<void> signOut() async {
    // 구글 쪽이 어떻게 되든 Firebase 로그아웃은 반드시 한다
    try {
      await _ensureGoogleReady();
      await _google.signOut();
    } catch (_) {
      // 구글로 로그인하지 않았거나 구글 초기화가 실패한 경우 — 할 일이 없다
    }
    await _auth.signOut();
  }

  static AuthFailureReason _reasonOf(FirebaseAuthException e) {
    switch (e.code) {
      // 이메일 열거 보호가 켜져 있으면 대부분 invalid-credential로 온다
      case 'invalid-credential':
      case 'invalid-email':
      case 'wrong-password':
      case 'user-not-found':
      case 'user-disabled':
        return AuthFailureReason.invalidCredentials;
      case 'email-already-in-use':
      case 'account-exists-with-different-credential':
        return AuthFailureReason.emailAlreadyInUse;
      case 'network-request-failed':
        return AuthFailureReason.network;
      default:
        return AuthFailureReason.unknown;
    }
  }
}
