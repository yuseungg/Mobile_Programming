// S02 가입 — 주인: C
// 1단계: 화면과 이동만. 닉네임 새로고침은 화면 안에서 가짜 목록을 돌린다.
// 입력 제한 · 중복 확인 · Firebase는 2단계.
import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../data/fakes/fake_data.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_text_field.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  int _nicknameIndex = 0;

  @override
  void dispose() {
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  void _refreshNickname() {
    setState(() {
      _nicknameIndex =
          (_nicknameIndex + 1) % FakeData.nicknameCandidates.length;
    });
  }

  void _goToSignIn() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.pushReplacementNamed(AppRoutes.signIn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.signUpTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(AppStrings.signUpHeading, style: AppText.poemTitle),
              const SizedBox(height: 6),
              const Text(AppStrings.signUpSubheading, style: AppText.bodySub),
              const SizedBox(height: 28),
              const AppTextField(
                label: AppStrings.signInEmailLabel,
                hintText: AppStrings.signInEmailHint,
                helperText: AppStrings.signUpEmailHelper,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 18),
              AppTextField(
                controller: _passwordController,
                label: AppStrings.signInPasswordLabel,
                hintText: AppStrings.signUpPasswordHint,
                helperText: AppStrings.signUpPasswordHelper,
                obscureText: true,
              ),
              const SizedBox(height: 18),
              AppTextField(
                controller: _passwordConfirmController,
                label: AppStrings.signUpPasswordConfirmLabel,
                hintText: AppStrings.signUpPasswordConfirmHint,
                obscureText: true,
                below: _PasswordMatch(
                  password: _passwordController,
                  confirm: _passwordConfirmController,
                ),
              ),
              const SizedBox(height: 24),
              _NicknameCard(
                nickname: FakeData.nicknameCandidates[_nicknameIndex],
                onRefresh: _refreshNickname,
              ),
              const SizedBox(height: 28),
              AppPrimaryButton(
                label: AppStrings.signUpButton,
                onPressed: () => Navigator.of(context)
                    .pushNamedAndRemoveUntil(AppRoutes.home, (_) => false),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(AppStrings.signUpHaveAccount,
                      style: AppText.caption),
                  TextButton(
                    onPressed: _goToSignIn,
                    child: const Text(AppStrings.signUpGoToSignIn),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 비밀번호 확인 칸 바로 아래 — 일치 여부 표시
class _PasswordMatch extends StatelessWidget {
  const _PasswordMatch({required this.password, required this.confirm});

  final TextEditingController password;
  final TextEditingController confirm;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([password, confirm]),
      builder: (context, _) {
        if (confirm.text.isEmpty) return const SizedBox.shrink();
        final isMatch = password.text == confirm.text;
        return Row(
          children: [
            Icon(
              isMatch ? Icons.check_circle : Icons.error_outline,
              size: 16,
              color: isMatch ? AppColors.confirmed : AppColors.accent,
            ),
            const SizedBox(width: 6),
            Text(
              isMatch
                  ? AppStrings.signUpPasswordMatch
                  : AppStrings.signUpPasswordMismatch,
              style: isMatch ? AppText.confirmedNotice : AppText.warningNotice,
            ),
          ],
        );
      },
    );
  }
}

/// 무작위 닉네임 — 입력칸이 아니다. 새로고침 버튼으로만 바뀐다.
class _NicknameCard extends StatelessWidget {
  const _NicknameCard({required this.nickname, required this.onRefresh});

  final String nickname;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 14, 8, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(AppStrings.signUpNicknameLabel, style: AppText.label),
              const Spacer(),
              Text(nickname, style: AppText.bodyStrong),
              IconButton(
                tooltip: AppStrings.signUpNicknameRefresh,
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded,
                    color: AppColors.textSub),
              ),
            ],
          ),
          const Text(AppStrings.signUpNicknameNotice, style: AppText.caption),
        ],
      ),
    );
  }
}
