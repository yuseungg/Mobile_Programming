// 설정(S10 · S11)의 모델 설명도 KR / EN을 따른다 — 폰에서 EN인데 「신중함 · 느림」이 남아 있었다
import 'package:flutter_test/flutter_test.dart';
import 'package:yeobaek/app/language.dart';
import 'package:yeobaek/data/settings_options.dart';

void main() {
  tearDown(() => appLanguage.value = AppLanguage.ko);

  test('모델 설명은 고른 언어로 나온다', () {
    final careful = modelOptions.first.model;
    final fast = modelOptions.last.model;

    expect(modelDescriptionOf(careful), '신중함 · 느림');
    expect(modelDescriptionOf(fast), '빠름');

    appLanguage.value = AppLanguage.en;
    expect(modelDescriptionOf(careful), 'Careful · slow');
    expect(modelDescriptionOf(fast), 'Fast');
  });

  test('모든 선택지에 영어 설명이 있다', () {
    for (final option in modelOptions) {
      expect(option.descriptionEn, isNotEmpty, reason: option.model);
    }
  });

  test('목록에 없는 모델은 설명이 없다', () {
    appLanguage.value = AppLanguage.en;
    expect(modelDescriptionOf('unknown/model'), '');
  });
}
