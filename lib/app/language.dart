// 주인: A — 앱 문구 언어 (KR / EN). 버튼은 lib/shared/widgets/language_toggle.dart
//
// 화면 문구는 AppStrings가 이 값을 보고 고른다. 바꾸면 main.dart의
// YeobaekApp이 화면 전체를 다시 그린다 — 입력 중인 글과 화면 이동 기록은 그대로다.
// 고른 언어는 기기에 남겨 두고 다음 실행에서 다시 읽는다.
//
// 처음 켜면 영어다 — 교수님 공지: "the main/initial selection of the language should be English".
// 테스트는 test/flutter_test_config.dart가 한국어로 시작하게 둔다 (기존 테스트가 한국어 문구로 찾는다).
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { ko, en }

/// 처음 켰을 때 · 남긴 값을 못 읽었을 때의 언어
const defaultAppLanguage = AppLanguage.en;

/// 지금 고른 언어. 기본은 영어 ([defaultAppLanguage]).
final appLanguage = ValueNotifier<AppLanguage>(defaultAppLanguage);

const _appLanguageKey = 'appLanguage';

/// 앱을 켤 때 한 번 — 지난번에 고른 언어를 읽는다. 처음이거나 못 읽으면 영어로 둔다.
Future<void> loadAppLanguage() async {
  try {
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getString(_appLanguageKey);
    appLanguage.value = AppLanguage.values.firstWhere(
      (language) => language.name == saved,
      orElse: () => defaultAppLanguage,
    );
  } catch (_) {
    appLanguage.value = defaultAppLanguage;
  }
}

/// 언어를 바꾸고 기기에 남긴다. 남기지 못해도 화면은 바로 바뀐다.
Future<void> changeAppLanguage(AppLanguage language) async {
  if (appLanguage.value == language) return;
  appLanguage.value = language;
  try {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_appLanguageKey, language.name);
  } catch (_) {
    // 다음 실행에서 기본 언어(영어)로 시작할 뿐, 지금 화면에는 영향이 없다.
  }
}

/// 지금 영어인가. 화면 문구(AppStrings)와 AI 지시문 · 검사가 같이 본다.
bool get isEnglish => appLanguage.value == AppLanguage.en;
