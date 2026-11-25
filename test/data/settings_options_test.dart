// 설정(S10 · S11)의 모델 설명도 KR / EN을 따른다 — 폰에서 EN인데 「신중함 · 느림」이 남아 있었다
import 'package:flutter_test/flutter_test.dart';
import 'package:yeobaek/app/language.dart';
import 'package:yeobaek/data/settings_options.dart';

void main() {
  tearDown(() => appLanguage.value = AppLanguage.ko);

  test('모델 설명은 고른 언어로 나온다', () {
    const multimodal = 'nvidia/nemotron-3.5-super-vl:free';

    expect(modelDescriptionOf(multimodal), '이미지도 읽음 · 신중함');

    appLanguage.value = AppLanguage.en;
    expect(modelDescriptionOf(multimodal), 'Reads images too · careful');
  });

  test('기본 모델은 목록에 있다 — 없으면 S10에 설명이 비고, 저장된 값도 기본값으로 못 돌아간다', () {
    final models = modelOptions.map((option) => option.model);
    expect(models, contains(defaultSettings.questionModel));
    expect(models, contains(defaultSettings.comparisonModel));
  });

  test('내려간 모델은 목록에 없다 (dots — 2026-11-25 404)', () {
    expect(
      modelOptions.map((option) => option.model),
      isNot(contains('dots-studio/dots-3-note-preview:free')),
    );
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
