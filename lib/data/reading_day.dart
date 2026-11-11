// 주인: C — 누적일수의 '하루' (기획서 7장 「누적일수 계산」)
//
// 하루는 한국 시간(UTC+9) 0시에 바뀐다. 기기 시간대와 상관없이 같은 날을 센다.
// Firestore 보안 규칙도 request.time에 9시간을 더해 같은 기준으로 비교한다.

const _koreaOffset = Duration(hours: 9);

/// 한국 시간 기준 날짜 (시각은 버린다).
DateTime readingDayOf(DateTime time) {
  final korea = time.toUtc().add(_koreaOffset);
  return DateTime.utc(korea.year, korea.month, korea.day);
}

/// 두 시각이 한국 시간으로 같은 날인가.
bool isSameReadingDay(DateTime a, DateTime b) =>
    readingDayOf(a) == readingDayOf(b);
