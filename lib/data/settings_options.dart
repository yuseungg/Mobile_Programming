// 주인: C — 설정(S10 · S11) 선택지와 기본값을 모아두는 곳
//
// ⚠ 모델 이름은 교수님 키로 열린 모델을 확인하기 전 임시 값이다 (기획서 9장 1번).
//   확인되면 이 파일만 고친다.

import 'models/settings.dart';

/// S11 모델 선택지. 질문 모델 · 비교 모델 둘 다 이 목록에서 고른다.
const modelOptions = <({String model, String description})>[
  (model: 'google/gemma-3-27b-it:free', description: '가장 신중함 · 느림'),
  (model: 'meta-llama/llama-4-maverick:free', description: '균형 · 보통'),
  (
    model: 'mistralai/mistral-small-3.2-24b-instruct:free',
    description: '가장 빠름',
  ),
];

/// 모델 이름 → S10 · S11에 함께 보여 줄 짧은 설명. 목록에 없으면 ''.
String modelDescriptionOf(String model) {
  for (final option in modelOptions) {
    if (option.model == model) return option.description;
  }
  return '';
}

/// 처음 설치했을 때의 설정. 질문은 신중한 모델, 비교는 빠른 모델 (기획서 6장).
const defaultSettings = Settings(
  questionModel: 'google/gemma-3-27b-it:free',
  comparisonModel: 'mistralai/mistral-small-3.2-24b-instruct:free',
  tone: Tone.plain,
);
