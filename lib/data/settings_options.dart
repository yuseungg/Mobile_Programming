// 주인: C — 설정(S10 · S11) 선택지와 기본값을 모아두는 곳
//
// 모델은 2026-11-17 A가 교수님 키로 확인한 무료 모델이다.
//   - nvidia/nemotron-3.5-lightning:free — 에이전트 루프에서 한국어 질문 · 툴 호출 확인. 한 턴 16~25초
//   - dots-studio/dots-3-note-preview:free — PoC · 휴대폰 앱에서 응답 확인. preview라 내려갈 수 있음
//   google/gemma 계열은 호출이 되지 않아(429) 뺐다. 바뀌면 이 파일만 고친다.
//   저장된 모델이 목록에 없으면 기본값으로 읽힌다 (PrefsSettingsRepository).

import '../app/language.dart';
import 'models/settings.dart';

/// S11 모델 선택지. 질문 모델 · 비교 모델 둘 다 이 목록에서 고른다.
/// 설명은 화면 오른쪽 위 KR / EN을 따른다 — 화면에서는 [modelDescriptionOf]로 꺼낸다.
const modelOptions = <({String model, String description, String descriptionEn})>[
  (
    model: 'nvidia/nemotron-3.5-lightning:free',
    description: '신중함 · 느림',
    descriptionEn: 'Careful · slow',
  ),
  (
    model: 'dots-studio/dots-3-note-preview:free',
    description: '빠름',
    descriptionEn: 'Fast',
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

/// 처음 설치했을 때의 설정. 질문은 신중한 모델(툴 호출 확인됨), 비교는 빠른 모델 (기획서 6장).
const defaultSettings = Settings(
  questionModel: 'nvidia/nemotron-3.5-lightning:free',
  comparisonModel: 'dots-studio/dots-3-note-preview:free',
  tone: Tone.plain,
);
