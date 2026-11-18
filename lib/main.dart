// 주인: C
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/router.dart';
import 'app/strings.dart';
import 'app/theme.dart';
import 'data/repositories.dart';
import 'firebase_options.dart';

/// 진짜 Firebase로 돌릴지. 기본은 켜짐. 가짜 데이터로 돌릴 때만:
///   flutter run --dart-define=USE_FIREBASE=false
/// (가짜 모드 데모 계정: demo@gmail.com / yeobaek1)
const _useFirebaseFlag = bool.fromEnvironment('USE_FIREBASE', defaultValue: true);

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
    Repositories.useFakes(signedOut: true); // S01부터 — 실제 앱처럼 로그인해서 들어간다
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
