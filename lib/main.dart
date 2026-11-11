// 주인: C
import 'package:flutter/material.dart';

import 'app/router.dart';
import 'app/strings.dart';
import 'app/theme.dart';
import 'data/repositories.dart';

void main() {
  // 2단계: Firebase 패키지가 들어오면 useFirebase()로 바꾼다.
  Repositories.useFakes();
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
