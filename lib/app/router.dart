// 주인: C — 라우터
// 라우트 이름: docs/여백-네이밍규칙.md 4장
// 화면 이동표: docs/여백-화면분업.md 3장
//
// 화면을 추가할 때는 AppRoutes에 경로 한 줄, onGenerateRoute에 한 줄만 넣는 작은 PR로.
import 'package:flutter/material.dart';

import '../features/auth/sign_in_screen.dart';
import '../features/auth/sign_up_screen.dart';
import '../features/chat/chat_screen.dart';
import '../features/community/community_detail_screen.dart';
import '../features/compare/comparison_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/reading/reading_screen.dart';
import '../features/save/save_screen.dart';
import '../features/settings/settings_edit_screen.dart';
import 'tab_shell.dart';

class AppRoutes {
  AppRoutes._();

  static const signIn = '/sign-in'; // S01
  static const signUp = '/sign-up'; // S02
  static const home = '/'; // S03 (탭: 시)
  static String reading(String poemId) => '/poems/$poemId'; // S04
  static String chat(String poemId) => '/poems/$poemId/chat'; // S05
  static String save(String poemId) => '/poems/$poemId/save'; // S06
  static String comparison(String poemId) => '/poems/$poemId/comparison'; // S07
  static const community = '/community'; // S08 (탭: 모두의 대화)
  static String communityDetail(String conversationId) =>
      '/community/$conversationId'; // S09
  static const settings = '/settings'; // S10 (탭: 설정)
  static const settingsEdit = '/settings/edit'; // S11
  static String profile(String userId) => '/profile/$userId'; // S12
}

class AppRouter {
  AppRouter._();

  /// 앱을 켜면 S01부터 (로그인 상태 확인은 2단계)
  static List<Route<dynamic>> onGenerateInitialRoutes(String initialRoute) => [
        onGenerateRoute(const RouteSettings(name: AppRoutes.signIn)),
      ];

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final segments = Uri.parse(settings.name ?? AppRoutes.home).pathSegments;

    final Widget page = switch (segments) {
      [] => const TabShell(initialTab: AppTab.poems),
      ['sign-in'] => const SignInScreen(),
      ['sign-up'] => const SignUpScreen(),
      ['poems', final poemId] => ReadingScreen(poemId: poemId),
      ['poems', final poemId, 'chat'] => ChatScreen(poemId: poemId),
      ['poems', final poemId, 'save'] => SaveScreen(poemId: poemId),
      ['poems', final poemId, 'comparison'] =>
        ComparisonScreen(poemId: poemId),
      ['community'] => const TabShell(initialTab: AppTab.community),
      ['community', final conversationId] =>
        CommunityDetailScreen(conversationId: conversationId),
      ['settings'] => const TabShell(initialTab: AppTab.settings),
      ['settings', 'edit'] => const SettingsEditScreen(),
      ['profile', final userId] => ProfileScreen(userId: userId),
      _ => const TabShell(initialTab: AppTab.poems),
    };

    return MaterialPageRoute<void>(builder: (_) => page, settings: settings);
  }

  /// 탭 화면(S03 · S08 · S10)으로 가면서 그 위에 쌓인 화면을 모두 닫는다.
  static void goToTab(BuildContext context, String tabRoute) {
    Navigator.of(context).pushNamedAndRemoveUntil(tabRoute, (_) => false);
  }
}
