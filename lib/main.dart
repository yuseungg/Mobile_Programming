// 주인: C
import 'package:flutter/material.dart';

import 'app/router.dart';
import 'app/strings.dart';
import 'app/theme.dart';

void main() {
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
