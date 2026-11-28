// 주인: C
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/language.dart';
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
  // 세로로 고정한다 — 가로로 돌리면 S05(위 시 · 아래 입력창 · 키보드)처럼 칸이 넘치는 화면이 있다.
  // 태블릿도 세로로 쓴다. AndroidManifest의 screenOrientation과 같은 뜻.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  if (_useFirebaseFlag && _canUseFirebase) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await Repositories.useFirebase();
  } else {
    Repositories.useFakes(signedOut: true); // S01부터 — 실제 앱처럼 로그인해서 들어간다
  }
  await loadAppLanguage();
  runApp(const YeobaekApp());
}

class YeobaekApp extends StatefulWidget {
  const YeobaekApp({super.key});

  @override
  State<YeobaekApp> createState() => _YeobaekAppState();
}

class _YeobaekAppState extends State<YeobaekApp> {
  @override
  void initState() {
    super.initState();
    appLanguage.addListener(_redrawEverything);
  }

  @override
  void dispose() {
    appLanguage.removeListener(_redrawEverything);
    super.dispose();
  }

  /// KR / EN을 바꾸면 쌓여 있는 화면까지 전부 다시 그린다 — 문구는 AppStrings가
  /// 그릴 때마다 읽으므로 다시 그리기만 하면 바뀐다. 위젯을 새로 만들지 않으니
  /// 입력 중인 글 · 스크롤 위치 · 화면 이동 기록은 그대로다.
  void _redrawEverything() {
    setState(() {});
    void markNeedsBuild(Element element) {
      element.markNeedsBuild();
      element.visitChildren(markNeedsBuild);
    }

    (context as Element).visitChildren(markNeedsBuild);
  }

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
