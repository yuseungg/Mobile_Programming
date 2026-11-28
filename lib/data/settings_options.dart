// 주인: C — 설정(S10 · S11) 선택지와 기본값을 모아두는 곳
//
// 모델은 요건 (a) 「무료 대형 멀티모달 모델」을 따른다. 2026-11-25 A가 실제 키로 확인했다.
//   - nvidia/nemotron-3.5-super-vl:free — 글 · 이미지 · 영상. verify_quote · search_poem_lines ·
//     compare_with_experts 모두 제대로 부름. 속으로 생각하게 두면 질문 하나에 17~35초라
//     앱은 생각을 끄고 부른다 (OpenRouterClient.reasoningOff) — 끈 힌트 실측 1~4초
//   - nvidia/nemotron-3.5-lightning:free — 글만. 툴 호출은 되지만 생각이 길어 힌트가 14~65초
//   뺀 것: dots-studio/dots-3-note-preview(2026-11-25 내려감, 404),
//          baidu/ernie-5.5-flash-preview(글만 받고, 저장 뒤 전문가 해석을 지어냄),
//          google/gemma 계열(호출이 되지 않음, 429)
//   바뀌면 이 파일만 고친다. 저장된 모델이 목록에 없으면 기본값으로 읽힌다 (PrefsSettingsRepository).

import '../app/language.dart';
import 'models/settings.dart';

/// S11 모델 선택지. 질문 모델 · 비교 모델 둘 다 이 목록에서 고른다.
/// 설명은 화면 오른쪽 위 KR / EN을 따른다 — 화면에서는 [modelDescriptionOf]로 꺼낸다.
const modelOptions = <({String model, String description, String descriptionEn})>[
  (
    model: 'nvidia/nemotron-3.5-super-vl:free',
    description: '이미지도 읽음 · 신중함',
    descriptionEn: 'Reads images too · careful',
  ),
  (
    model: 'nvidia/nemotron-3.5-lightning:free',
    description: '글만 읽음 · 느림',
    descriptionEn: 'Text only · slow',
  ),
];

/// 모델 이름 → S10 · S11에 함께 보여 줄 짧은 설명 (지금 고른 언어로). 목록에 없으면 ''.
String modelDescriptionOf(String model) {
  for (final option in modelOptions) {
    if (option.model == model) {
      return isEnglish ? option.descriptionEn : option.description;
    }
  }
  return '';
}

/// 처음 설치했을 때의 설정. 질문 · 비교 모두 멀티모달 모델 (요건 a).
/// 비교용으로 쓰던 빠른 모델(dots)이 내려갔고, 대신할 빠른 무료 멀티모달 모델이 아직 없다.
const defaultSettings = Settings(
  questionModel: 'nvidia/nemotron-3.5-super-vl:free',
  comparisonModel: 'nvidia/nemotron-3.5-super-vl:free',
  tone: Tone.plain,
);
