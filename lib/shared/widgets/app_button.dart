// 주인: A — 공용 버튼
import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// 가로로 꽉 차는 주 버튼 (먹색).
/// [isUnlock]이 true면 와인색 — 해석 '저장하기'처럼 잠금을 여는 버튼에만 쓴다.
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isUnlock = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isUnlock;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: isUnlock
            ? FilledButton.styleFrom(backgroundColor: AppColors.accent)
            : null,
        child: Text(label),
      ),
    );
  }
}

/// 가로로 꽉 차는 보조 버튼 (테두리)
class AppSecondaryButton extends StatelessWidget {
  const AppSecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final iconData = icon;
    return SizedBox(
      width: double.infinity,
      child: iconData == null
          ? OutlinedButton(onPressed: onPressed, child: Text(label))
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(iconData, size: 20),
              label: Text(label),
            ),
    );
  }
}
