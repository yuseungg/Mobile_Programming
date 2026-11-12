// 주인: C
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/router.dart';
import 'app/strings.dart';
import 'app/theme.dart';
import 'data/repositories.dart';
import 'firebase_options.dart';

/// 진짜 Firebase로 돌릴지. 지금은 직접 켤 때만:
///   flutter run --dart-define=USE_FIREBASE=true
///
/// 로그인 분기(S01 → S03)가 들어오기 전까지는 기본이 가짜 저장소다.
/// 지금 화면들은 로그인 안 했을 때 가짜 사용자 id를 쓰는데,
/// 진짜 Firestore에서는 보안 규칙이 그걸 막기 때문이다.
const _useFirebaseFlag = bool.fromEnvironment('USE_FIREBASE');

/// Firebase 설정은 Android용만 있다 (firebase_options.dart).
/// 웹(Chrome) · Windows에서는 켜도 가짜 저장소로 돈다.
bool get _canUseFirebase =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (_useFirebaseFlag && _canUseFirebase) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await Repositories.useFirebase();
  } else {
    Repositories.useFakes();
  }
  runApp(const YeobaekApp());
}

class YeobaekApp extends StatelessWidget {
  const YeobaekApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      onGenerateRoute: AppRouter.onGenerateRoute,
      onGenerateInitialRoutes: AppRouter.onGenerateInitialRoutes,
    );
  }
}
