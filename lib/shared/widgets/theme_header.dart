// 화면 위 머리 띠 — 주인: B (docs/여백-테마설계.md 6 · 7장)
// 머리 띠 그림 + 오른쪽 아래 마스코트 + 뒤로 가기 · 제목 · 오른쪽 버튼(언어 토글 등)
// Scaffold의 appBar 자리에 그대로 넣으면 됨
import 'package:flutter/material.dart';

import '../../app/poem_theme.dart';

class ThemeHeader extends StatelessWidget implements PreferredSizeWidget {
  const ThemeHeader({super.key, this.theme = YeobaekTheme.defaults, this.title, this.actions = const []});

  final YeobaekTheme theme;
  final Widget? title;
  final List<Widget> actions;

  // 너비 따라 커지면 태블릿에서 화면을 너무 먹어서 고정 (테마설계 7장)
  // 폰 너비(약 375)에서 3:1 그림이 거의 안 잘리는 높이
  static const double height = 120;

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 그림 불러오는 동안이나 못 불러오면 단색
        ColoredBox(color: theme.headerTint),
        Image.asset(
          theme.headerImage,
          fit: BoxFit.cover,
          // 넓은 화면에선 위아래가 잘리는데 언덕 · 눈 같은 게 아래에 있어서 아래 기준
          alignment: Alignment.bottomCenter,
          errorBuilder: (context, error, stackTrace) => const SizedBox(),
        ),
        // 위쪽 버튼(언어 토글)이랑 안 겹치게 툴바 아래에
        Positioned(
          right: 16,
          bottom: 4,
          height: 64,
          child: Image.asset(
            theme.mascot,
            errorBuilder: (context, error, stackTrace) => const SizedBox(),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: AppBar(
            backgroundColor: Colors.transparent,
            title: title,
            actions: actions,
          ),
        ),
      ],
    );
  }
}
