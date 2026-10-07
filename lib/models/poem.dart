import 'expert_reading.dart';
import 'poem_badge.dart';

/// 시 데이터 모델
class Poem {
  final String id;
  final String title;
  final String poet;
  final int year;
  final List<String> lines; // 시의 각 행 (1행 = lines[0])
  final String historicalContext; // 창작 배경 (사실만 서술)
  final List<ExpertReading> expertReadings; // 전문가 해석 A, B
  final PoemBadge badge; // 시 완독 뱃지

  const Poem({
    required this.id,
    required this.title,
    required this.poet,
    required this.year,
    required this.lines,
    required this.historicalContext,
    required this.expertReadings,
    required this.badge,
  });

  int get lineCount => lines.length;

  /// 행 번호(1-indexed)로 행 텍스트 조회
  String getLine(int lineNumber) {
    if (lineNumber >= 1 && lineNumber <= lines.length) {
      return lines[lineNumber - 1];
    }
    return '';
  }
}
