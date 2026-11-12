import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeobaek/data/local/prefs_settings_repository.dart';
import 'package:yeobaek/data/models/settings.dart';
import 'package:yeobaek/data/settings_options.dart';

void main() {
  Future<PrefsSettingsRepository> repoWith(
    Map<String, Object> values, {
    DateTime Function()? now,
  }) async {
    SharedPreferences.setMockInitialValues(values);
    return PrefsSettingsRepository(await SharedPreferences.getInstance(),
        now: now);
  }

  test('저장한 적이 없으면 기본 설정', () async {
    final repo = await repoWith({});
    final settings = await repo.load();
    expect(settings.questionModel, defaultSettings.questionModel);
    expect(settings.comparisonModel, defaultSettings.comparisonModel);
    expect(settings.tone, defaultSettings.tone);
  });

  test('저장한 설정을 다시 불러온다 (S11 → S10)', () async {
    final repo = await repoWith({});
    final changed = Settings(
      questionModel: modelOptions.last.model,
      comparisonModel: modelOptions.first.model,
      tone: Tone.gentle,
    );
    await repo.save(changed);

    final loaded = await repo.load();
    expect(loaded.questionModel, changed.questionModel);
    expect(loaded.comparisonModel, changed.comparisonModel);
    expect(loaded.tone, Tone.gentle);
  });

  test('목록에서 사라진 모델 이름이 저장돼 있으면 기본값으로', () async {
    final repo = await repoWith({
      'settings.questionModel': 'old/removed-model:free',
      'settings.tone': 'unknown',
    });
    final settings = await repo.load();
    expect(settings.questionModel, defaultSettings.questionModel);
    expect(settings.tone, defaultSettings.tone);
  });

  test('호출 횟수는 달마다 따로 센다 (한국 시간 기준)', () async {
    var now = DateTime.utc(2026, 11, 30, 14); // 한국 11/30 23시
    final repo = await repoWith({}, now: () => now);

    await repo.countQuestionCall();
    await repo.countQuestionCall();
    await repo.countComparisonCall();
    var usage = await repo.usageThisMonth();
    expect(usage.questionCount, 2);
    expect(usage.comparisonCount, 1);

    now = DateTime.utc(2026, 11, 30, 15); // 한국 12/1 0시 — 새 달
    usage = await repo.usageThisMonth();
    expect(usage.questionCount, 0);
    expect(usage.comparisonCount, 0);
  });
}
