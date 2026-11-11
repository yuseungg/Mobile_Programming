// 주인: C — 가짜 계정. Firebase 없이 S01 · S02 흐름을 눌러보기 위한 것.
//
// 미리 있는 계정: demo@gmail.com / yeobaek1 → FakeData.myUserId
// 구글 로그인은 언제나 FakeData.myUserId로 로그인된다.

import 'dart:async';

import '../repositories/auth_repository.dart';
import 'fake_data.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({String? signedInUserId}) : _userId = signedInUserId;

  static const demoEmail = 'demo@gmail.com';
  static const demoPassword = 'yeobaek1';

  final _accounts = <String, ({String password, String userId})>{
    demoEmail: (password: demoPassword, userId: FakeData.myUserId),
  };
  final _changes = StreamController<String?>.broadcast();
  String? _userId;
  var _nextId = 1;

  @override
  String? get currentUserId => _userId;

  @override
  Stream<String?> userIdChanges() async* {
    yield _userId;
    yield* _changes.stream;
  }

  void _set(String? userId) {
    _userId = userId;
    _changes.add(userId);
  }

  @override
  Future<String> signInWithEmail(String email, String password) async {
    final account = _accounts[email.trim().toLowerCase()];
    if (account == null || account.password != password) {
      throw const AuthFailure(AuthFailureReason.invalidCredentials);
    }
    _set(account.userId);
    return account.userId;
  }

  @override
  Future<String> signUpWithEmail(String email, String password) async {
    final key = email.trim().toLowerCase();
    if (!key.endsWith('@gmail.com')) {
      throw const AuthFailure(AuthFailureReason.notGmail);
    }
    if (_accounts.containsKey(key)) {
      throw const AuthFailure(AuthFailureReason.emailAlreadyInUse);
    }
    final userId = 'fake_user_${_nextId++}';
    _accounts[key] = (password: password, userId: userId);
    _set(userId);
    return userId;
  }

  @override
  Future<String> signInWithGoogle() async {
    _set(FakeData.myUserId);
    return FakeData.myUserId;
  }

  @override
  Future<void> signOut() async => _set(null);
}
