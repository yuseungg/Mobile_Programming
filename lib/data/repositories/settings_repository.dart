// 주인: C — 설정 (F6 · S10 S11), 기기에 저장 (SharedPreferences)
// 사용: A(에이전트가 모델 이름 · 말투를 읽고, 호출 횟수를 센다)
//
// '이번 달 사용량'은 공용 키라 OpenRouter 값을 쓰지 않고 앱이 직접 센다.
// 기기마다 따로 센다. 달이 바뀌면(한국 시간) 0부터 다시 센다.

import '../models/settings.dart';

abstract interface class SettingsRepository {
  /// 저장된 값이 없으면 settings_options.dart의 defaultSettings.
  Future<Settings> load();

  Future<void> save(Settings settings);

  Future<({int questionCount, int comparisonCount})> usageThisMonth();

  /// A — 질문 모델을 한 번 부를 때마다 (툴 라운드 포함).
  Future<void> countQuestionCall();

  /// A · D — 비교 모델을 한 번 부를 때마다.
  Future<void> countComparisonCall();
}
