// 주인: C — S01 · S02 입력 제약 (기획서 5장 「입력 제약」)
//
// 이메일: gmail.com 주소만 · 공백은 입력 자체가 안 됨
// 비밀번호: 6자 이상 · 영문 소문자와 숫자만. 공백 · 대문자 · 한글 · 특수기호는 입력 자체가 안 됨
// 길이: 이메일 64자 · 비밀번호 32자까지만 입력된다 (긴 글을 붙여 넣어도 칸이 넘치지 않게)

import 'package:flutter/services.dart';

import '../../app/strings.dart';
import '../../data/repositories.dart';

const minPasswordLength = 6;
const maxEmailLength = 64;
const maxPasswordLength = 32;

final _gmailPattern = RegExp(r'^[a-z0-9._%+-]+@gmail\.com$');
final _passwordPattern = RegExp(r'^[a-z0-9]+$');

/// 이메일 칸 — 공백을 막고 [maxEmailLength]자까지만 받는다.
final emailInputFormatters = <TextInputFormatter>[
  FilteringTextInputFormatter.deny(RegExp(r'\s')),
  LengthLimitingTextInputFormatter(maxEmailLength),
];

/// 비밀번호 칸 — 영문 소문자와 숫자만, [maxPasswordLength]자까지만 받는다.
final passwordInputFormatters = <TextInputFormatter>[
  FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9]')),
  LengthLimitingTextInputFormatter(maxPasswordLength),
];

bool isValidGmail(String email) =>
    _gmailPattern.hasMatch(email.trim().toLowerCase());

bool isValidPassword(String password) =>
    password.length >= minPasswordLength && _passwordPattern.hasMatch(password);

/// 로그인 · 가입 실패 이유 → 화면에 보일 문구
String authFailureMessage(AuthFailureReason reason) => switch (reason) {
      AuthFailureReason.invalidCredentials => AppStrings.authErrorInvalidCredentials,
      AuthFailureReason.emailAlreadyInUse => AppStrings.authErrorEmailInUse,
      AuthFailureReason.notGmail => AppStrings.authErrorNotGmail,
      AuthFailureReason.network => AppStrings.authErrorNetwork,
      AuthFailureReason.cancelled => '',
      AuthFailureReason.unknown => AppStrings.authErrorUnknown,
    };
