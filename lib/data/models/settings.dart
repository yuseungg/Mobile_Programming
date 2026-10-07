// 주인: C · 용어: docs/여백-네이밍규칙.md 2장 「설정」

enum Tone {
  plain, // 담백하게
  gentle, // 부드럽게
}

class Settings {
  const Settings({
    required this.questionModel,
    required this.comparisonModel,
    required this.tone,
  });

  final String questionModel; // OpenRouter 모델 이름 — 질문 · 힌트
  final String comparisonModel; // OpenRouter 모델 이름 — 비교 · 요약
  final Tone tone;
}
