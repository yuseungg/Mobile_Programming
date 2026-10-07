// 주인: A — 구역 이름 (작은 고딕 라벨)
import 'package:flutter/material.dart';

import '../../app/theme.dart';

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final trailingWidget = trailing;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(child: Text(text, style: AppText.label)),
          if (trailingWidget != null) trailingWidget,
        ],
      ),
    );
  }
}
