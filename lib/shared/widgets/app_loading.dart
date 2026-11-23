// 주인: D — 공용 로딩 (기다리는 동안 「멈춘 게 아니다」를 보여 준다)
//
// 지금까지는 화면마다 날것 CircularProgressIndicator를 놓았다. 그것은 멈춤과
// 진행을 잘 구분해 주지 않고, 명조 중심 화면에 머티리얼 기본 모양이 섞인다.
//
// 두 가지를 같이 둔다.
//  - [AppLoading]  — 자리만 차지하는 위젯. FutureBuilder 안에 그대로 끼운다.
//  - [LoadingPage] — 화면 하나를 채우는 쪽. 라우트로 띄울 수 있다.
// 다른 파트 화면은 고치지 않았다. 각자 자기 화면에서 스피너를 이것으로
// 바꿔 끼우면 된다 (바꾸는 쪽은 아래 「테스트에서」를 함께 읽는다).
//
// ── 마스코트 ──
// assets/mascot/mascot.png. 책을 읽는 병아리다.
// 다른 그림으로 바꾸려면 `AppLoading(mascot: ...)`에 위젯을 넘긴다.
//
// 걸음은 세 가지를 겹쳐 만든다 — 위아래로 통통 뛰고(bob), 디딜 때마다 몸이
// 기울고(tilt), 좌우로 조금 오갔다 온다(travel). 좌우반전은 **쓰지 않는다**:
// 그림이 좌우대칭이 아니라(책·목도리) 돌아설 때 책이 반대 손으로 건너뛴다.
//
// ── 테스트에서 ──
// 끝나지 않는 애니메이션이므로 pumpAndSettle은 시간 초과된다 (스피너도 같다).
// test/support/pump.dart의 pumpUntilLoaded를 쓴다 — 그 helper는 스피너와
// 이 위젯을 둘 다 기다린다.
// 애니메이션을 끈 기기(MediaQuery.disableAnimations)에서는 아예 돌지 않고
// 멈춘 모습으로 그린다. 그 경우에는 pumpAndSettle도 끝난다.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/strings.dart';
import '../../app/theme.dart';

/// 기다리는 동안 보여 주는 위젯. 마스코트가 뚜방뚜방 걷고, 아래 글자가
/// 한 글자씩 파도치듯 튄다.
class AppLoading extends StatefulWidget {
  const AppLoading({
    super.key,
    this.label = AppStrings.loadingLabel,
    this.mascot,
    this.size = 72,
  });

  /// 마스코트 그림. 쓰는 쪽에서 바꿀 일이 없으면 둘 필요 없다.
  static const assetPath = 'assets/mascot/mascot.png';

  /// 글자. 한 글자씩 튄다. 비우면 마스코트만 걷는다.
  final String label;

  /// 걷는 그림. 비우면 [assetPath]의 마스코트.
  final Widget? mascot;

  /// 마스코트 한 변의 길이.
  final double size;

  /// 기본 마스코트에 붙는 키. 테스트에서 걸음을 짚을 때 쓴다.
  static const defaultMascotKey = Key('appLoadingMascot');

  @override
  State<AppLoading> createState() => _AppLoadingState();
}

class _AppLoadingState extends State<AppLoading>
    with SingleTickerProviderStateMixin {
  /// 한 바퀴. 이 안에 두 걸음과 글자 파도 한 번이 들어간다.
  static const _period = Duration(milliseconds: 1400);

  late final AnimationController _controller =
      AnimationController(vsync: this, duration: _period);

  bool _isRunning = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 애니메이션을 끈 기기에서는 돌리지 않는다. 멈춘 그림으로도 뜻은 전해지고,
    // 돌려 두면 그 설정을 쓰는 사람과 pumpAndSettle이 둘 다 막힌다.
    final shouldRun = !MediaQuery.disableAnimationsOf(context);
    if (shouldRun == _isRunning) return;
    _isRunning = shouldRun;
    if (shouldRun) {
      _controller.repeat();
    } else {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.label.isEmpty ? null : widget.label,
      liveRegion: true,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _WalkingMascot(
                t: t,
                size: widget.size,
                child: widget.mascot,
              ),
              if (widget.label.isNotEmpty) ...[
                const SizedBox(height: 14),
                _WaveLabel(t: t, label: widget.label),
              ],
            ],
          );
        },
      ),
    );
  }
}

// ── 마스코트 ──────────────────────────────────────────

/// 걸음. 한 바퀴에 두 걸음을 딛고, 오른쪽으로 갔다가 왼쪽으로 돌아온다.
/// 되돌아오게 둔 이유는 한쪽으로만 가면 한 바퀴 끝에서 제자리로 튀기 때문이다.
class _WalkingMascot extends StatelessWidget {
  const _WalkingMascot({required this.t, required this.size, this.child});

  final double t;
  final double size;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    // 한 걸음 안에서의 위치 (0 → 1이 한 걸음)
    final step = (t * 2) % 1;
    // 발을 디딜 때마다 살짝 솟았다 내려온다
    final bob = -math.sin(step * math.pi) * size * 0.06;
    // 몸이 걸음에 따라 좌우로 기운다 — 「뚜방뚜방」은 여기서 나온다
    final tilt = math.sin(t * 4 * math.pi) * 0.06;
    // 삼각파: 0 → 1 → 0. 가다가 돌아온다
    final travel = t < 0.5 ? t * 2 : (1 - t) * 2;
    final dx = (travel - 0.5) * size * 0.5;
    // 떠 있을수록 그림자가 작아진다. 이게 없으면 바닥에 붙은 알약처럼 보인다
    final shadow = 1 - math.sin(step * math.pi) * 0.3;

    return SizedBox(
      width: size * 1.6,
      height: size * 1.25,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // 그림자는 몸과 함께 옆으로만 움직인다 (위아래로는 따라가지 않는다)
          Positioned(
            bottom: 0,
            child: Transform.translate(
              offset: Offset(dx, 0),
              child: Container(
                width: size * 0.5 * shadow,
                height: size * 0.08,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(size),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: size * 0.06,
            child: Transform.translate(
              offset: Offset(dx, bob),
              child: Transform.rotate(
                angle: tilt,
                child: child ??
                    Image.asset(
                      AppLoading.assetPath,
                      key: AppLoading.defaultMascotKey,
                      width: size,
                      height: size,
                      fit: BoxFit.contain,
                      // 그림이 아직 없거나 깨져도 기다리는 중인 것은 보여야 한다
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.hourglass_empty_rounded,
                        size: size * 0.6,
                        color: AppColors.textFaint,
                      ),
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 글자 파도 ─────────────────────────────────────────

/// 「LOADING......」을 한 글자씩 띄워 두고, 앞에서 뒤로 차례로 튀어 오르게 한다.
class _WaveLabel extends StatelessWidget {
  const _WaveLabel({required this.t, required this.label});

  final double t;
  final String label;

  /// 글자 사이의 시간 차. 이 값이 파도의 기울기다.
  static const _stagger = 0.045;

  /// 한 글자가 튀어 올라 돌아오는 데 쓰는 시간 (한 바퀴 중의 비율)
  static const _hop = 0.3;

  static const _height = 7.0;

  /// 고딕 작은 글씨에 자간만 벌렸다. 글자마다 따로 그리므로 Row가 붙여 주는
  /// 간격이 없어서, 자간을 조금 주지 않으면 글자가 달라붙는다.
  /// theme.dart에 새 스타일을 넣지 않는다 — 그 파일은 주인 외 금지다.
  static const _style = TextStyle(
    fontFamily: AppFonts.gothic,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textSub,
    letterSpacing: 1.5,
  );

  @override
  Widget build(BuildContext context) {
    // split('')은 UTF-16 코드 유닛 단위다. 라틴 글자와 완성형 한글은 한 글자씩
    // 끊기므로 이 문구에는 맞다. 이모지를 넣으려면 characters 패키지가 필요하다.
    final chars = label.split('');
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < chars.length; i++)
          Transform.translate(
            offset: Offset(0, _dyOf(i)),
            child: Text(chars[i], style: _style),
          ),
      ],
    );
  }

  double _dyOf(int index) {
    // 내 차례가 오기까지 기다린다. 1을 넘으면 앞으로 돌아온다
    final local = (t - index * _stagger) % 1;
    if (local >= _hop) return 0; // 튀어 오를 때가 아니면 제자리
    return -math.sin(local / _hop * math.pi) * _height;
  }
}

// ── 화면 하나를 채우는 쪽 ─────────────────────────────

/// 라우트로 띄울 수 있는 로딩 화면.
///
/// 화면 전환 자체를 가로채지는 않는다 — 그것은 `lib/app/router.dart`가 할 일이고
/// 그 파일은 주인 외 금지다. 여기서는 **부를 수 있는 화면**만 둔다. 쓰는 쪽은 둘이다.
///
/// 1. 다음 화면이 뜰 때까지 이것을 먼저 보여 준다
///    `Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoadingPage()))`
/// 2. 화면 안에서 데이터를 기다리는 동안 body로 쓴다
///    `snapshot.hasData ? _body(...) : const LoadingPage(title: AppStrings.comparisonTitle)`
class LoadingPage extends StatelessWidget {
  const LoadingPage({super.key, this.title, this.label, this.mascot});

  /// 앱바에 넣을 제목. 비우면 앱바를 두지 않는다 (가는 중인 화면의 제목을 모를 때).
  final String? title;

  /// [AppLoading.label]로 넘긴다.
  final String? label;

  /// [AppLoading.mascot]으로 넘긴다.
  final Widget? mascot;

  @override
  Widget build(BuildContext context) {
    final heading = title;
    return Scaffold(
      appBar: heading == null
          ? null
          : AppBar(title: Text(heading, style: AppText.screenTitle)),
      body: Center(
        child: AppLoading(
          label: label ?? AppStrings.loadingLabel,
          mascot: mascot,
        ),
      ),
    );
  }
}
