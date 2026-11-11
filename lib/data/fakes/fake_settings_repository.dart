// 주인: C — 가짜 설정 저장소. 앱을 끄면 처음 값으로 돌아간다.

import '../models/settings.dart';
import '../repositories/settings_repository.dart';
import 'fake_data.dart';

class FakeSettingsRepository implements SettingsRepository {
  Settings _settings = FakeData.settings;
  int _questionCount = FakeData.usageQuestionCount;
  int _comparisonCount = FakeData.usageComparisonCount;

  @override
  Future<Settings> load() async => _settings;

  @override
  Future<void> save(Settings settings) async => _settings = settings;

  @override
  Future<({int questionCount, int comparisonCount})> usageThisMonth() async =>
      (questionCount: _questionCount, comparisonCount: _comparisonCount);

  @override
  Future<void> countQuestionCall() async => _questionCount++;

  @override
  Future<void> countComparisonCall() async => _comparisonCount++;
}
