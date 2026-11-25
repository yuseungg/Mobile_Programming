// S02 가입 — 주인: C
// 이메일 가입 + 무작위 닉네임 (요건 b). 입력 제약은 auth_input_rules.dart.
// 가입 직후에는 S13을 건너뛰고 바로 홈으로 — 보여 줄 기록이 아직 없다 (PR #27 리뷰).
//
// [isNicknameOnly]: 구글로 처음 로그인한 사람처럼 계정은 있는데 프로필이 없을 때.
// 이메일 · 비밀번호 칸을 숨기고 닉네임만 정한다 (화면을 새로 만들지 않고 S02를 다시 쓴다).
import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../data/nickname_words.dart';
import '../../data/repositories.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/language_toggle.dart';
import 'auth_input_rules.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key, this.isNicknameOnly = false});

  final bool isNicknameOnly;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  String _nickname = drawNickname();
  bool _isBusy = false;

  /// 계정은 만들었는데 프로필 저장이 실패했을 때, 다시 누르면 계정을 또 만들지 않는다.
  String? _createdUserId;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  bool get _isEmailValid => isValidGmail(_emailController.text);
  bool get _isPasswordValid => isValidPassword(_passwordController.text);
  bool get _isPasswordConfirmed =>
      _passwordConfirmController.text == _passwordController.text;

  bool get _canSubmit =>
      !_isBusy &&
      (widget.isNicknameOnly ||
          (_isEmailValid && _isPasswordValid && _isPasswordConfirmed));

  void _refreshNickname() {
    setState(() => _nickname = drawNickname(except: _nickname));
  }

  Future<void> _submit() async {
    setState(() => _isBusy = true);
    try {
      final userId = widget.isNicknameOnly
          ? Repositories.auth.currentUserId
          : (_createdUserId ??= await Repositories.auth.signUpWithEmail(
              _emailController.text.trim().toLowerCase(),
              _passwordController.text,
            ));
      if (userId == null) {
        // 닉네임만 정하는 화면인데 로그인이 풀린 경우
        _goToSignIn();
        return;
      }

      final confirmed = await Repositories.user.createProfile(userId, _nickname);
      if (!mounted) return;
      if (confirmed != _nickname) {
        _showMessage(AppStrings.signUpNicknameAdjusted(confirmed));
      }
      Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);
    } on AuthFailure catch (e) {
      _showMessage(authFailureMessage(e.reason));
    } catch (error) {
      debugPrint('[auth] 알 수 없는 오류: $error');
      _showMessage(AppStrings.authErrorUnknown);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  /// 닉네임만 정하는 화면에서 다른 계정으로 — 로그아웃하고 S01로
  Future<void> _useOtherAccount() async {
    await Repositories.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.signIn, (_) => false);
  }

  void _goToSignIn() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.pushReplacementNamed(AppRoutes.signIn);
    }
  }

  void _showMessage(String message) {
    if (!mounted || message.isEmpty) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isNicknameOnly = widget.isNicknameOnly;
    final showEmailError = _emailController.text.isNotEmpty && !_isEmailValid;
    final showPasswordShort = _passwordController.text.isNotEmpty &&
        _passwordController.text.length < minPasswordLength;

    return Scaffold(
      appBar: AppBar(
        title: Text(isNicknameOnly
            ? AppStrings.nicknameOnlyTitle
            : AppStrings.signUpTitle),
        automaticallyImplyLeading: !isNicknameOnly,
        actions: const [LanguageToggle()],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isNicknameOnly
                    ? AppStrings.nicknameOnlyHeading
                    : AppStrings.signUpHeading,
                style: AppText.poemTitle,
              ),
              const SizedBox(height: 6),
              Text(
                isNicknameOnly
                    ? AppStrings.nicknameOnlySubheading
                    : AppStrings.signUpSubheading,
                style: AppText.bodySub,
              ),
              const SizedBox(height: 28),
              if (!isNicknameOnly) ...[
                AppTextField(
                  controller: _emailController,
                  label: AppStrings.signInEmailLabel,
                  hintText: AppStrings.signInEmailHint,
                  helperText: AppStrings.signUpEmailHelper,
                  keyboardType: TextInputType.emailAddress,
                  inputFormatters: emailInputFormatters,
                  onChanged: (_) => setState(() {}),
                  below: showEmailError
                      ? Text(AppStrings.signUpEmailInvalid,
                          style: AppText.warningNotice)
                      : null,
                ),
                const SizedBox(height: 18),
                AppTextField(
                  controller: _passwordController,
                  label: AppStrings.signInPasswordLabel,
                  hintText: AppStrings.signUpPasswordHint,
                  helperText: AppStrings.signUpPasswordHelper,
                  obscureText: true,
                  inputFormatters: passwordInputFormatters,
                  onChanged: (_) => setState(() {}),
                  below: showPasswordShort
                      ? Text(AppStrings.signUpPasswordTooShort(minPasswordLength),
                          style: AppText.warningNotice)
                      : null,
                ),
                const SizedBox(height: 18),
                AppTextField(
                  controller: _passwordConfirmController,
                  label: AppStrings.signUpPasswordConfirmLabel,
                  hintText: AppStrings.signUpPasswordConfirmHint,
                  obscureText: true,
                  inputFormatters: passwordInputFormatters,
                  onChanged: (_) => setState(() {}),
                  below: _PasswordMatch(
                    password: _passwordController,
                    confirm: _passwordConfirmController,
                  ),
                ),
                const SizedBox(height: 24),
              ],
              _NicknameCard(
                nickname: _nickname,
                onRefresh: _isBusy ? null : _refreshNickname,
              ),
              const SizedBox(height: 28),
              AppPrimaryButton(
                label: isNicknameOnly
                    ? AppStrings.nicknameOnlyButton
                    : AppStrings.signUpButton,
                onPressed: _canSubmit ? _submit : null,
              ),
              const SizedBox(height: 16),
              if (isNicknameOnly)
                Center(
                  child: TextButton(
                    onPressed: _isBusy ? null : _useOtherAccount,
                    child: Text(AppStrings.nicknameOnlyOtherAccount),
                  ),
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(AppStrings.signUpHaveAccount,
                        style: AppText.caption),
                    TextButton(
                      onPressed: _isBusy ? null : _goToSignIn,
                      child: Text(AppStrings.signUpGoToSignIn),
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
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 14, 8, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(AppStrings.signUpNicknameLabel, style: AppText.label),
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
          Text(AppStrings.signUpNicknameNotice, style: AppText.caption),
        ],
      ),
    );
  }
}
