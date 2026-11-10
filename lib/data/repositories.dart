// 주인: C — 저장소를 한 곳에서 갈아끼운다.
//
// 화면과 에이전트는 구현(Fake… / Firestore…)을 직접 만들지 않고 여기서 꺼내 쓴다.
//   final profile = await Repositories.user.fetchProfile(userId);
//
// 가짜 → 진짜 교체는 main.dart에서 useFakes() 대신 useFirebase()를 부르는 것 하나뿐이다.
// (useFirebase()는 Firebase 패키지가 들어온 뒤 추가한다.)

import 'fakes/fake_auth_repository.dart';
import 'fakes/fake_public_conversation_repository.dart';
import 'fakes/fake_reading_repository.dart';
import 'fakes/fake_settings_repository.dart';
import 'fakes/fake_store.dart';
import 'fakes/fake_user_repository.dart';
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

  /// 메모리 안의 가짜 데이터로 돈다. Firebase 없이 화면을 끝까지 눌러볼 때.
  /// [signedInUserId]를 주면 로그인된 상태로 시작한다 (테스트 · 화면 개발용).
  static void useFakes({String? signedInUserId}) {
    final store = FakeStore();
    auth = FakeAuthRepository(signedInUserId: signedInUserId);
    user = FakeUserRepository(store);
    reading = FakeReadingRepository(store);
    publicConversation = FakePublicConversationRepository(store, auth: auth);
    settings = FakeSettingsRepository();
  }
}
