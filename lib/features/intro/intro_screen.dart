// S13 안내 — 주인: D
//
// S01 로그인(· S02 가입) 다음, S03 홈 앞에 들어가는 화면이다. 로그인할
// 때마다 매번 보인다.
//
// 세 칸이 위에서 아래로 놓이고, 맨 밑에 「시 읽으러 가기」가 있다.
// 오른쪽 위의 「건너뛰기」는 스크롤과 무관하게 고정이다 — 세 화면을 내려가지
// 않고도 바로 홈으로 갈 수 있다. (PR #27 리뷰 — 승민)
//   1) 앱 이름
//   2) 마음에 남은 줄 — 시마다 하나씩, 왼쪽부터 번지듯 드러난다
//   3) 지금까지 — 읽은 날 · 나눈 글 · 받은 뱃지
//
// 버튼을 누르지 않아도 30초가 지나면 저절로 홈으로 넘어간다.
//
// 「마음에 남은 줄」은 S06 마지막 질문에서 고른 Reading.impressiveLine이다.
// 아직 고른 적이 없으면 그 칸은 안내 한 줄만 남는다. Reading은 시마다
// 하나라서 같은 시를 다시 읽으면 저절로 최신 것으로 덮인다.
import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../ports/reading_source.dart';
import '../../ports/repository_reading_source.dart';
import '../../shared/widgets/app_button.dart';
import 'inking_text.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({
    super.key,
    this.source = const RepositoryReadingSource(),
    this.autoAdvance = autoAdvanceDelay,
  });

  final ReadingSource source;

  /// 자동으로 넘어가기까지의 시간. 테스트에서만 바꾼다.
  final Duration autoAdvance;

  /// 30초 — 버튼을 누르지 않아도 이만큼 지나면 넘어간다.
  static const autoAdvanceDelay = Duration(seconds: 30);

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

/// 화면이 그리는 데 필요한 것 — 한 번에 읽어 온다.
class _IntroData {
  const _IntroData({
    required this.lines,
    required this.days,
    required this.shared,
    required this.badges,
  });

  /// 마음에 남은 줄 — 시 제목과 그 줄
  final List<({String title, String text})> lines;
  final int days;
  final int shared;
  final int badges;
}

class _IntroScreenState extends State<IntroScreen> {
  Timer? _timer;
  late final Future<_IntroData> _data = _load();

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

  Future<_IntroData> _load() async {
    final source = widget.source;
    final readings = await source.myReadings();
    final profile = await source.profileById(source.myUserId);

    final lines = <({String title, String text})>[];
    for (final reading in readings) {
      final lineNo = reading.impressiveLine;
      if (lineNo == null) continue;
      final poem = await source.poemById(reading.poemId);
      // 행 번호가 시 밖을 가리키면 조용히 건너뛴다 — 안내 화면이 깨지면 안 된다
      if (lineNo < 1 || lineNo > poem.lines.length) continue;
      lines.add((title: poem.title, text: poem.lineAt(lineNo)));
    }

    return _IntroData(
      lines: lines,
      days: profile.totalReadingDays,
      shared: readings.where((r) => r.isSaved && r.isPublic).length,
      badges: profile.badgeIds.length,
    );
  }

  void _goHome() {
    _timer?.cancel();
    if (!mounted) return;
    AppRouter.goToTab(context, AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    // 한 칸 = 한 화면. 기기가 달라져도 스크롤 횟수가 같다 — 세 칸이니
    // 아래로 두어 번 넘기면 버튼에 닿는다.
    final blockHeight = MediaQuery.sizeOf(context).height;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 56, 28, 32),
              child: FutureBuilder<_IntroData>(
                future: _data,
                builder: (context, snapshot) {
                  final data = snapshot.data;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Block(
                        height: blockHeight,
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(AppStrings.appName, style: AppText.appName),
                            SizedBox(height: 4),
                            Text(AppStrings.appSubtitle, style: AppText.bodySub),
                          ],
                        ),
                      ),
                      _Block(
                        height: blockHeight,
                        // 읽어 오는 동안은 빈 칸이다 — 글이 번지는 것을 처음부터
                        // 보여 주려고 자리만 잡아 둔다.
                        child: data == null
                            ? const SizedBox.shrink()
                            : _ImpressiveLines(lines: data.lines),
                      ),
                      _Block(
                        height: blockHeight,
                        child: data == null
                            ? const SizedBox.shrink()
                            : _Status(
                                days: data.days,
                                shared: data.shared,
                                badges: data.badges,
                              ),
                      ),
                      AppPrimaryButton(
                        label: AppStrings.introStart,
                        onPressed: _goHome,
                      ),
                    ],
                  );
                },
              ),
            ),
            // 스크롤과 함께 움직이지 않는다. 밑의 버튼까지 두어 번
            // 넘기지 않아도 여기서 바로 나갈 수 있다.
            Positioned(
              top: 0,
              right: 0,
              child: TextButton(
                onPressed: _goHome,
                child: const Text(AppStrings.introSkip,
                    style: AppText.caption),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 한 화면 높이의 칸. 내용은 가운데에서 왼쪽으로 붙인다.
class _Block extends StatelessWidget {
  const _Block({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        child: Align(alignment: Alignment.centerLeft, child: child),
      );
}

class _ImpressiveLines extends StatelessWidget {
  const _ImpressiveLines({required this.lines});

  final List<({String title, String text})> lines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(AppStrings.introLinesTitle, style: AppText.sectionTitle),
        const SizedBox(height: 24),
        if (lines.isEmpty)
          const Text(AppStrings.introLinesEmpty, style: AppText.bodySub)
        else
          for (final (index, line) in lines.indexed) ...[
            if (index > 0) const SizedBox(height: 28),
            InkingText(
              text: line.text,
              style: AppText.poemLine,
              // 한 줄씩 차례로 번진다
              delay: Duration(milliseconds: 400 + index * 900),
            ),
            const SizedBox(height: 6),
            Text(line.title, style: AppText.caption),
          ],
      ],
    );
  }
}

class _Status extends StatelessWidget {
  const _Status({
    required this.days,
    required this.shared,
    required this.badges,
  });

  final int days;
  final int shared;
  final int badges;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(AppStrings.introStatusTitle, style: AppText.sectionTitle),
        const SizedBox(height: 20),
        Text(AppStrings.introDays(days), style: AppText.body),
        const SizedBox(height: 10),
        Text(AppStrings.introShared(shared), style: AppText.body),
        const SizedBox(height: 10),
        Text(AppStrings.introBadges(badges), style: AppText.body),
      ],
    );
  }
}
