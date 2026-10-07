// 주인: D — 시 뱃지 (문구 없이 이미지만)
// 지금은 아이콘으로 자리만 잡아둔다.
// 아스트라 이미지가 assets/badges/{poemId}.png 로 들어오면 Image.asset으로 바꾼다.
import 'package:flutter/material.dart';

import '../../app/theme.dart';

class BadgeImage extends StatelessWidget {
  const BadgeImage({super.key, required this.poemId, this.size = 72});

  final String poemId; // 뱃지 id = poemId
  final double size;

  IconData get _placeholderIcon => switch (poemId) {
        'seosi' => Icons.star_rounded, // 서시 → 별
        'jindallae' => Icons.local_florist_rounded, // 진달래꽃 → 꽃
        'bomgoyangi' => Icons.pets_rounded, // 봄은 고양이로다 → 고양이
        _ => Icons.auto_awesome_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.accentBg,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border),
      ),
      child: Icon(_placeholderIcon, size: size * 0.5, color: AppColors.accent),
    );
  }
}
