// 주인: D — 글자가 왼쪽부터 번지듯 드러나는 글월 (S13)
//
// 여백이 글로 메워지는 모양을 낸다. 글자를 하나씩 세는 대신 가로 그라디언트
// 마스크를 왼쪽에서 오른쪽으로 밀어, 번지는 가장자리가 부드럽게 지나가게 한다.
//
// 기기에서 애니메이션을 꺼 둔 사람에게는 처음부터 다 보여 준다 (접근성).
import 'dart:async';

import 'package:flutter/material.dart';

class InkingText extends StatefulWidget {
  const InkingText({
    super.key,
    required this.text,
    required this.style,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 1600),
  });

  final String text;
  final TextStyle style;

  /// 여러 줄을 차례로 번지게 할 때 쓰는 시작 지연
  final Duration delay;
  final Duration duration;

  @override
  State<InkingText> createState() => _InkingTextState();
}

class _InkingTextState extends State<InkingText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _progress =
      CurvedAnimation(parent: _controller, curve: Curves.easeOut);

  Timer? _delay;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1; // 애니메이션을 끈 기기 — 그냥 다 보여 준다
      return;
    }
    // Timer로 둔다 — dispose에서 끊어야 화면을 떠난 뒤에 남지 않는다.
    _delay = Timer(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _delay?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Text(widget.text, style: widget.style);

    return AnimatedBuilder(
      animation: _progress,
      child: text,
      builder: (context, child) {
        if (_progress.value >= 1) return child!;
        // 번지는 가장자리의 너비 — 글월 가로폭의 20%쯤
        const edge = 0.2;
        final head = _progress.value * (1 + edge);
        return ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: const [Colors.black, Colors.black, Colors.transparent],
            stops: [
              0,
              (head - edge).clamp(0.0, 1.0),
              head.clamp(0.0, 1.0),
            ],
          ).createShader(rect),
          child: child,
        );
      },
    );
  }
}
