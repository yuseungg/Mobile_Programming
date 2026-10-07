// 주인: C — 하단 탭바
// 탭바는 S03 · S08 · S10에서만 보인다. 순서: 시 / 모두의 대화 / 설정
// 나머지 화면은 탭바 없이 왼쪽 위 뒤로 가기로 돌아온다.
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          HomeScreen(),
          CommunityListScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
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
