// 주인: A — 글자 수 표시
// 1단계는 표시만 한다. 입력을 막는 건 2단계 (화면분업 4장).
import 'package:flutter/material.dart';

import '../../app/strings.dart';
import '../../app/theme.dart';

class CharCounter extends StatelessWidget {
  const CharCounter({super.key, required this.controller, required this.max});

  final TextEditingController controller;
  final int max;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final count = value.text.length;
        return Text(
          AppStrings.charCount(count, max),
          style: AppText.caption.copyWith(
            color: count > max ? AppColors.accent : AppColors.textFaint,
          ),
        );
      },
    );
  }
}
