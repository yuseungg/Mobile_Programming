// 주인: C — 저장소를 한 곳에서 갈아끼운다.
//
// 화면과 에이전트는 구현(Fake… / Firestore…)을 직접 만들지 않고 여기서 꺼내 쓴다.
//   final profile = await Repositories.user.fetchProfile(userId);
//
// 가짜 → 진짜 교체는 main.dart에서 useFakes() 대신 useFirebase()를 부르는 것 하나뿐이다.

import 'package:shared_preferences/shared_preferences.dart';

import 'fakes/fake_auth_repository.dart';
import 'fakes/fake_data.dart';
import 'fakes/fake_public_conversation_repository.dart';
import 'fakes/fake_reading_repository.dart';
import 'fakes/fake_settings_repository.dart';
import 'fakes/fake_store.dart';
import 'fakes/fake_user_repository.dart';
import 'firestore/firebase_auth_repository.dart';
import 'firestore/firestore_public_conversation_repository.dart';
import 'firestore/firestore_reading_repository.dart';
import 'firestore/firestore_user_repository.dart';
import 'local/prefs_settings_repository.dart';
import 'repositories/auth_repository.dart';
import 'repositories/public_conversation_repository.dart';
import 'repositories/reading_repository.dart';
import 'repositories/settings_repository.dart';
import 'repositories/user_repository.dart';

export 'repositories/auth_repository.dart';
export 'repositories/public_conversation_repository.dart';
export 'repositories/reading_repository.dart';
export 'repositories/settings_repository.dart';
export 'repositories/user_repository.dart';

class Repositories {
  Repositories._();

  static late AuthRepository auth;
  static late UserRepository user;
  static late ReadingRepository reading;
  static late PublicConversationRepository publicConversation;
  static late SettingsRepository settings;

  /// 로그인한 사람의 uid. 화면은 로그인 뒤에만 열리므로 여기서 꺼내 쓴다.
  /// 로그아웃 상태에서 부르면 [StateError] — 로그인 안 한 사람이 남의 id로 쓰는 일을 막는다.
  static String get userId {
    final id = auth.currentUserId;
    if (id == null) throw StateError('로그인하지 않은 상태다');
    return id;
  }

  /// 메모리 안의 가짜 데이터로 돈다. Firebase 없이 화면을 끝까지 눌러볼 때.
  /// 기본은 데모 사용자(FakeData.myUserId)로 로그인된 채 시작한다 — 화면 하나만 띄우는 테스트용.
  /// [signedInUserId]로 다른 사용자, [signedOut]이면 로그아웃 상태(S01부터)로 시작한다.
  static void useFakes({String? signedInUserId, bool signedOut = false}) {
    final store = FakeStore();
    auth = FakeAuthRepository(
      signedInUserId: signedOut ? null : (signedInUserId ?? FakeData.myUserId),
    );
    user = FakeUserRepository(store);
    reading = FakeReadingRepository(store);
    publicConversation = FakePublicConversationRepository(store, auth);
    settings = FakeSettingsRepository();
  }

  /// 진짜 Firebase (Auth · Firestore)와 기기 저장소(SharedPreferences)로 돈다.
  /// 부르기 전에 Firebase.initializeApp이 끝나 있어야 한다.
  static Future<void> useFirebase() async {
    auth = FirebaseAuthRepository();
    user = FirestoreUserRepository();
    reading = FirestoreReadingRepository();
    publicConversation = FirestorePublicConversationRepository();
    settings = PrefsSettingsRepository(await SharedPreferences.getInstance());
  }
}
