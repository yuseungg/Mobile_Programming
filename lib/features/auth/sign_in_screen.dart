// S01 로그인 — 주인: C
// 1단계: 화면과 이동만. Firebase Auth · 입력 제한(gmail만, 비밀번호 문자 차단)은 2단계.
import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../data/fakes/fake_data.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_text_field.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  void _goHome(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    // 앱 이름 아래 한 줄 — 서시 10행
    final quote = FakeData.poemById('seosi').lineAt(10);

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
              const SizedBox(height: 24),
              _PoemQuote(text: quote),
              const SizedBox(height: 40),
              const AppTextField(
                label: AppStrings.signInEmailLabel,
                hintText: AppStrings.signInEmailHint,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 18),
              const AppTextField(
                label: AppStrings.signInPasswordLabel,
                hintText: AppStrings.signInPasswordHint,
                obscureText: true,
              ),
              const SizedBox(height: 28),
              AppPrimaryButton(
                label: AppStrings.signInButton,
                onPressed: () => _goHome(context),
              ),
              const SizedBox(height: 20),
              const _OrDivider(),
              const SizedBox(height: 20),
              AppSecondaryButton(
                label: AppStrings.signInGoogleButton,
                icon: Icons.account_circle_outlined,
                onPressed: () => _goHome(context),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(AppStrings.signInNoAccount, style: AppText.caption),
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context).pushNamed(AppRoutes.signUp),
                    child: const Text(AppStrings.signInGoToSignUp),
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

/// 왼쪽에 세로줄이 있는 시 한 줄
class _PoemQuote extends StatelessWidget {
  const _PoemQuote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 14),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: AppColors.border, width: 2)),
      ),
      child: Text(text, style: AppText.poemQuote),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider()),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(AppStrings.signInOr, style: AppText.caption),
        ),
        Expanded(child: Divider()),
      ],
    );
  }
}
