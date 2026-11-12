// 주인: C — 진짜 설정 저장소 (기기에 저장, SharedPreferences)
//
// 이번 달 사용량은 달마다 키를 따로 둔다 (한국 시간 기준 'usage.2026-11.question').
// 달이 바뀌면 새 키라서 자연히 0부터 센다.

import 'package:shared_preferences/shared_preferences.dart';

import '../models/settings.dart';
import '../reading_day.dart';
import '../repositories/settings_repository.dart';
import '../settings_options.dart';

class PrefsSettingsRepository implements SettingsRepository {
  PrefsSettingsRepository(this._prefs, {DateTime Function()? now})
      : _now = now ?? DateTime.now;

  final SharedPreferences _prefs;
  final DateTime Function() _now;

  static const _questionModelKey = 'settings.questionModel';
  static const _comparisonModelKey = 'settings.comparisonModel';
  static const _toneKey = 'settings.tone';

  String _usageKey(String kind) {
    final day = readingDayOf(_now());
    final month = day.month.toString().padLeft(2, '0');
    return 'usage.${day.year}-$month.$kind';
  }

  static String _knownModelOr(String? saved, String fallback) =>
      modelOptions.any((o) => o.model == saved) ? saved! : fallback;

  @override
  Future<Settings> load() async {
    final toneName = _prefs.getString(_toneKey);
    return Settings(
      // 모델 목록이 바뀌어 저장된 이름이 사라졌으면 기본값으로
      questionModel: _knownModelOr(
          _prefs.getString(_questionModelKey), defaultSettings.questionModel),
      comparisonModel: _knownModelOr(_prefs.getString(_comparisonModelKey),
          defaultSettings.comparisonModel),
      tone: Tone.values.firstWhere(
        (t) => t.name == toneName,
        orElse: () => defaultSettings.tone,
      ),
    );
  }

  @override
  Future<void> save(Settings settings) async {
    await _prefs.setString(_questionModelKey, settings.questionModel);
    await _prefs.setString(_comparisonModelKey, settings.comparisonModel);
    await _prefs.setString(_toneKey, settings.tone.name);
  }

  @override
  Future<({int questionCount, int comparisonCount})> usageThisMonth() async =>
      (
        questionCount: _prefs.getInt(_usageKey('question')) ?? 0,
        comparisonCount: _prefs.getInt(_usageKey('comparison')) ?? 0,
      );

  Future<void> _count(String kind) async {
    final key = _usageKey(kind);
    await _prefs.setInt(key, (_prefs.getInt(key) ?? 0) + 1);
  }

  @override
  Future<void> countQuestionCall() => _count('question');

  @override
  Future<void> countComparisonCall() => _count('comparison');
}
