// S01 로그인 — 주인: C
// 이메일 · 구글 로그인 (요건 b). 입력 제약은 auth_input_rules.dart.
// 로그인 뒤 프로필이 있으면 S13 안내를 거쳐 홈으로, 없으면(구글 첫 로그인 등) S02 닉네임 정하기로.
// 자동 로그인(앱을 다시 켰을 때)은 S01을 거치지 않으므로 S13도 보이지 않는다 — 로그인 분기(④).
import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../data/fakes/fake_data.dart';
import '../../data/repositories.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_text_field.dart';
import 'auth_input_rules.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isBusy = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      !_isBusy &&
      isValidGmail(_emailController.text) &&
      _passwordController.text.isNotEmpty;

  Future<void> _signInWithEmail() =>
      _run(() => Repositories.auth.signInWithEmail(
            _emailController.text.trim().toLowerCase(),
            _passwordController.text,
          ));

  Future<void> _signInWithGoogle() =>
      _run(Repositories.auth.signInWithGoogle);

  /// 로그인을 시도하고, 프로필이 있으면 S13 안내로, 없으면 닉네임 정하기로 간다.
  Future<void> _run(Future<String> Function() signIn) async {
    setState(() => _isBusy = true);
    try {
      final userId = await signIn();
      final hasProfile = await Repositories.user.hasProfile(userId);
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        hasProfile ? AppRoutes.intro : AppRoutes.signUpNickname,
        (_) => false,
      );
    } on AuthFailure catch (e) {
      _showMessage(authFailureMessage(e.reason));
    } catch (error) {
      debugPrint('[auth] 알 수 없는 오류: $error');
      _showMessage(AppStrings.authErrorUnknown);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted || message.isEmpty) return; // 구글 창을 닫은 경우는 조용히
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
              AppTextField(
                controller: _emailController,
                label: AppStrings.signInEmailLabel,
                hintText: AppStrings.signInEmailHint,
                keyboardType: TextInputType.emailAddress,
                inputFormatters: emailInputFormatters,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 18),
              AppTextField(
                controller: _passwordController,
                label: AppStrings.signInPasswordLabel,
                hintText: AppStrings.signInPasswordHint,
                obscureText: true,
                inputFormatters: passwordInputFormatters,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 28),
              AppPrimaryButton(
                label: AppStrings.signInButton,
                onPressed: _canSubmit ? _signInWithEmail : null,
              ),
              const SizedBox(height: 20),
              const _OrDivider(),
              const SizedBox(height: 20),
              AppSecondaryButton(
                label: AppStrings.signInGoogleButton,
                icon: Icons.account_circle_outlined,
                onPressed: _isBusy ? null : _signInWithGoogle,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(AppStrings.signInNoAccount, style: AppText.caption),
                  TextButton(
                    onPressed: _isBusy
                        ? null
                        : () => Navigator.of(context).pushNamed(AppRoutes.signUp),
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
