// S13 안내 — 주인: D
//
// S01 로그인(· S02 가입) 다음, S03 홈 앞에 한 번 들어가는 화면이다.
// 로그인할 때마다 매번 보인다.
//
// 두 가지만 한다.
//   1) 아래로 두세 번 스크롤할 수 있고, 맨 밑에 「시 학습하러 가기」가 있다.
//   2) 버튼을 누르지 않아도 15초 뒤에 저절로 홈으로 넘어간다.
//
// 본문 문구는 아직 비어 있다. [_sections]에 문구를 넣으면 그 칸에 뜨고,
// 빈 문자열이면 그 칸은 여백으로 남는다. 칸 수가 스크롤 분량을 정한다
// (한 칸 ≒ 한 화면 높이).
import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../shared/widgets/app_button.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key, this.autoAdvance = autoAdvanceDelay});

  /// 자동으로 넘어가기까지의 시간. 테스트에서만 바꾼다.
  final Duration autoAdvance;

  /// 15초 — 버튼을 누르지 않아도 이만큼 지나면 넘어간다.
  static const autoAdvanceDelay = Duration(seconds: 15);

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  /// 본문 문구. 아직 비워 둔 상태다 — 한 칸이 한 화면쯤 된다.
  static const _sections = <String>['', '', ''];

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.autoAdvance, _goHome);
  }

  @override
  void dispose() {
    // 화면을 떠난 뒤에 타이머가 살아 있으면, 사용자가 이미 다른 화면에 가 있는데
    // 홈이 한 번 더 밀려 들어온다. 반드시 여기서 끊는다.
    _timer?.cancel();
    super.dispose();
  }

  void _goHome() {
    _timer?.cancel();
    if (!mounted) return;
    AppRouter.goToTab(context, AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    // 한 칸의 높이 = 한 화면. 화면 높이에 맞춰 두면 기기가 달라져도
    // 스크롤 횟수가 같다 — 세 칸이면 아래로 두세 번 넘기면 버튼에 닿는다.
    final sectionHeight = MediaQuery.sizeOf(context).height;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 56, 28, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(AppStrings.appName, style: AppText.appName),
              const SizedBox(height: 4),
              const Text(AppStrings.appSubtitle, style: AppText.bodySub),
              for (final text in _sections)
                SizedBox(
                  height: sectionHeight,
                  child: text.isEmpty
                      ? null
                      : Align(
                          alignment: Alignment.centerLeft,
                          child: Text(text, style: AppText.body),
                        ),
                ),
              AppPrimaryButton(
                label: AppStrings.introStart,
                onPressed: _goHome,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
