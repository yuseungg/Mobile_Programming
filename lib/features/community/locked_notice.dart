// 잠금 안내 — 주인: D
// 기획서 5장 「잠금 한 곳」: S06에서 저장해야 S07·S08·S09가 그 시에 대해 열린다.
// 저장하지 않은 시의 남의 대화는 어디서도 볼 수 없다.
//
// 화면 분기만으로는 우회할 수 있다. 실제 차단은 C의 Firestore 보안 규칙이
// 맡고(기획서 7장), 이 위젯은 사람에게 이유를 보여 주는 쪽이다.
import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';

/// 읽어 오지 못했을 때 (잠금 예외 · 네트워크 · 그 밖의 실패).
///
/// D 화면 네 개(S07 · S08 · S09 · S12)가 같이 쓴다. 이유를 단정하지 않는다 —
/// C의 저장소는 저장하지 않은 시의 대화를 읽으면 예외를 던지고, 네트워크
/// 실패도 같은 자리로 온다. 둘을 구분해 문구를 고르는 것은 저장소의 예외
/// 타입이 들어온 뒤에 한다. 지금 중요한 것은 **스피너가 영원히 돌지 않는 것**이다.
class UnavailableNotice extends StatelessWidget {
  const UnavailableNotice({super.key, this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined,
              size: 32, color: AppColors.textFaint),
          const SizedBox(height: 16),
          Text(
            AppStrings.noticeUnavailable,
            style: AppText.bodySub,
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 20),
            TextButton(
              onPressed: onRetry,
              child: const Text(AppStrings.noticeUnavailableAction),
            ),
          ],
        ],
      ),
    );
  }
}

class LockedNotice extends StatelessWidget {
  const LockedNotice({super.key, required this.poemId});

  /// 읽으러 갈 시. null이면 읽기로 보내는 버튼을 숨긴다.
  final String? poemId;

  @override
  Widget build(BuildContext context) {
    final target = poemId;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        children: [
          const Icon(Icons.lock_outline, size: 32, color: AppColors.textFaint),
          const SizedBox(height: 16),
          Text(
            AppStrings.communityLockedTitle,
            style: AppText.bodyStrong,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.communityLockedBody,
            style: AppText.bodySub,
            textAlign: TextAlign.center,
          ),
          if (target != null) ...[
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.of(context).pushNamed(
                AppRoutes.reading(target),
              ),
              child: const Text(AppStrings.communityLockedAction),
            ),
          ],
        ],
      ),
    );
  }
}
