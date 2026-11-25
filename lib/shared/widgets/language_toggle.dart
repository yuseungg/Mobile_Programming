// 주인: A — KR / EN 전환 버튼 (세그먼티드 컨트롤)
//
// 모든 화면의 오른쪽 위에 둔다.
// - AppBar가 있는 화면: actions의 맨 끝에 `LanguageToggle()`.
//   이미 있던 버튼은 그대로 두고, 그 오른쪽에 붙는다.
// - 불러오는 중 · 실패처럼 제목이 아직 없는 화면: `appBar: LanguageToggleAppBar()`.
// - AppBar가 없는 화면: body를 Stack으로 감싸고 `LanguageToggleCorner()`.
//   AppBar 안에 있을 때와 같은 높이 · 같은 여백에 놓인다.
import 'package:flutter/material.dart';

import '../../app/language.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';

class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key});

  static const _segmentWidth = 34.0;
  static const _height = 28.0;
  static const _radius = 14.0;

  /// 화면 오른쪽 끝과의 간격. AppBar 안팎에서 같다.
  static const endPadding = 12.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: endPadding),
      child: Center(
        widthFactor: 1,
        child: ValueListenableBuilder<AppLanguage>(
          valueListenable: appLanguage,
          builder: (context, selected, _) => Semantics(
            container: true,
            label: AppStrings.languageToggleLabel,
            child: Container(
              height: _height,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(_radius),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Segment(
                    label: AppStrings.languageKorean,
                    isSelected: selected == AppLanguage.ko,
                    onTap: () => changeAppLanguage(AppLanguage.ko),
                  ),
                  _Segment(
                    label: AppStrings.languageEnglish,
                    isSelected: selected == AppLanguage.en,
                    onTap: () => changeAppLanguage(AppLanguage.en),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: LanguageToggle._segmentWidth,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accent : AppColors.card,
            borderRadius: BorderRadius.circular(LanguageToggle._radius - 2),
          ),
          child: Text(
            label,
            style: isSelected
                ? AppText.tagOnAccent
                : AppText.tagOnAccent.copyWith(color: AppColors.textSub),
          ),
        ),
      ),
    );
  }
}

/// AppBar가 없는 화면용. Stack 안에 넣으면 오른쪽 위, AppBar 높이의 가운데에 놓인다.
class LanguageToggleCorner extends StatelessWidget {
  const LanguageToggleCorner({super.key});

  @override
  Widget build(BuildContext context) {
    return const Positioned(
      top: 0,
      right: 0,
      child: SafeArea(
        child: SizedBox(height: kToolbarHeight, child: LanguageToggle()),
      ),
    );
  }
}

/// 제목 없이 KR / EN만 있는 AppBar. 불러오는 중 · 실패 화면에서 쓴다 —
/// 내용이 뜬 뒤의 AppBar와 같은 자리에 있어서 버튼이 깜빡이거나 움직이지 않는다.
class LanguageToggleAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const LanguageToggleAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) =>
      AppBar(actions: const [LanguageToggle()]);
}
