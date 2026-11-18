// 주인: C — 앱을 켜면 맨 처음 지나는 관문 (로그인 분기 ④). 화면 번호는 없다.
//
//   로그인 안 됨                 → S01
//   로그인됨 + 프로필 있음       → S03 홈 (S13 안내는 S01에서 직접 로그인했을 때만)
//   로그인됨 + 프로필 없음       → S02 닉네임만 정하기 (구글로 들어왔다가 정하지 않고 끈 경우)
//   확인하다 실패 (인터넷 등)   → 안내 + 다시 시도
//
// Firebase는 앱을 켠 직후 로그인 상태를 조금 늦게 알려 준다. currentUserId를 바로 보면
// 로그인된 사람도 S01로 튕길 수 있어서, 첫 로그인 상태 알림을 기다린 뒤에 판단한다.
import 'package:flutter/material.dart';

import '../data/repositories.dart';
import 'router.dart';
import 'strings.dart';
import 'theme.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _hasFailed = false;

  @override
  void initState() {
    super.initState();
    _decide();
  }

  void _retry() {
    setState(() {
      _hasFailed = false;
    });
    _decide();
  }

  Future<void> _decide() async {
    try {
      final userId = await Repositories.auth.userIdChanges().first;
      final String route;
      if (userId == null) {
        route = AppRoutes.signIn;
      } else if (await Repositories.user.hasProfile(userId)) {
        route = AppRoutes.home;
      } else {
        route = AppRoutes.signUpNickname;
      }
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(route, (_) => false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasFailed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _hasFailed
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      AppStrings.authGateFailed,
                      style: AppText.bodySub,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _retry,
                      child: const Text(AppStrings.authGateRetry),
                    ),
                  ],
                ),
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}
