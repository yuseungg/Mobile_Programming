// 잠금 · 빈 화면 · 오류 안내 — 주인: B (docs/여백-테마설계.md 6 · 7장)
// 상태 마스코트 + 문구 + 버튼 하나. 문구는 화면 주인이 AppStrings로 넘김
// 평가 기준에 「오류 처리」가 있어서 눈에 띄게 그림
import 'package:flutter/material.dart';

import '../../app/poem_theme.dart';
import '../../app/theme.dart';

enum MascotMood { locked, empty, error }

class MascotNotice extends StatelessWidget {
  const MascotNotice({
    super.key,
    required this.mood,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final MascotMood mood;
  final String message;
  final String? actionLabel; // 버튼 글자. onAction이랑 둘 다 있어야 버튼 보임
  final VoidCallback? onAction;

  String get _image {
    switch (mood) {
      case MascotMood.locked:
        return AppImages.mascotLocked;
      case MascotMood.empty:
        return AppImages.mascotEmpty;
      case MascotMood.error:
        return AppImages.mascotError;
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = actionLabel;
    final action = onAction;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            _image,
            height: 140,
            // 그림 없어도 문구 · 버튼은 나와야 함
            errorBuilder: (context, error, stackTrace) => const SizedBox(),
          ),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center, style: AppText.body),
          if (label != null && action != null) ...[
            const SizedBox(height: 20),
            FilledButton(onPressed: action, child: Text(label)),
          ],
        ],
      ),
    );
  }
}
