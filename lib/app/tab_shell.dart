// 주인: C — 하단 탭바
// 탭바는 S03 · S08 · S10에서만 보인다. 순서: 시 / 모두의 대화 / 설정
// 나머지 화면은 탭바 없이 왼쪽 위 뒤로 가기로 돌아온다.
// 설정 탭은 누를 때마다 새로 만든다 — 그사이 늘어난 이번 달 사용량을 다시 읽도록.
import 'package:flutter/material.dart';

import '../features/community/community_list_screen.dart';
import '../features/home/home_screen.dart';
import '../features/settings/settings_screen.dart';
import 'strings.dart';

enum AppTab { poems, community, settings }

class TabShell extends StatefulWidget {
  const TabShell({super.key, this.initialTab = AppTab.poems});

  final AppTab initialTab;

  @override
  State<TabShell> createState() => _TabShellState();
}

class _TabShellState extends State<TabShell> {
  late int _index = widget.initialTab.index;
  int _settingsOpenCount = 0; // 설정 탭을 누른 횟수 — S10의 key
  // 모두의 대화 탭을 누른 횟수 — S08이 자물쇠를 다시 읽는 신호.
  // S10처럼 key로 다시 만들지 않는 이유는 CommunityListScreen.openCount에 적었다.
  int _communityOpenCount = 0;

  void _select(int index) {
    setState(() {
      if (index == AppTab.settings.index) _settingsOpenCount++;
      if (index == AppTab.community.index) _communityOpenCount++;
      _index = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          const HomeScreen(),
          CommunityListScreen(openCount: _communityOpenCount),
          SettingsScreen(key: ValueKey(_settingsOpenCount)),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: AppStrings.tabPoems,
          ),
          NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            selectedIcon: Icon(Icons.forum),
            label: AppStrings.tabCommunity,
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: AppStrings.tabSettings,
          ),
        ],
      ),
    );
  }
}
