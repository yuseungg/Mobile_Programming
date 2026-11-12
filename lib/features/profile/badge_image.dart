// 주인: D — 시 뱃지 (문구 없이 이미지만, 기획서 6장)
//
// 뱃지 이미지는 assets/badges/{poemId}.png다. 시 하나를 추가할 때
// 본문 JSON · 전문가 해석 · 뱃지 이미지가 한 세트로 들어간다 (기획서 11장).
//
// 이미지가 아직 없으면 그 시를 닮은 아이콘으로 대신 보여 준다. 뱃지는
// 프로필의 보상이라, 파일 하나가 없다고 화면이 깨지면 안 된다.
import 'package:flutter/material.dart';

import '../../app/theme.dart';

class BadgeImage extends StatelessWidget {
  const BadgeImage({super.key, required this.poemId, this.size = 72});

  final String poemId; // 뱃지 id = poemId
  final double size;

  /// 뱃지 이미지 에셋 경로 — 전문가 해석 파일의 `badge` 값과 같은 자리
  static String assetPathFor(String poemId) => 'assets/badges/$poemId.png';

  /// 이미지가 없을 때 쓰는 아이콘 (기획서: 서시 → 별, 진달래꽃 → 꽃,
  /// 봄은 고양이로다 → 고양이)
  IconData get _fallbackIcon => switch (poemId) {
        'seosi' => Icons.star_rounded,
        'jindallae' => Icons.local_florist_rounded,
        'bomgoyangi' => Icons.pets_rounded,
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
      child: ClipOval(
        child: Image.asset(
          assetPathFor(poemId),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Icon(
            _fallbackIcon,
            size: size * 0.5,
            color: AppColors.accent,
          ),
        ),
      ),
    );
  }
}
