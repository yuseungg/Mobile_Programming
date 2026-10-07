/// 전문가의 개별 주장 및 근거 행
class ExpertClaim {
  final List<int> lines; // 근거 행 번호 (1-indexed)
  final String point; // 핵심 문장/주장

  const ExpertClaim({
    required this.lines,
    required this.point,
  });
}

/// 전문가 해석 모델 (시마다 둘 이상 배정)
class ExpertReading {
  final String label; // "전문가 해석 A", "전문가 해석 B"
  final String stance; // "부끄러움과 다짐으로 읽는 입장"
  final List<ExpertClaim> claims;
  final String fullText; // 평론 요약 본문 (원문 인용 포함)
  final String comparisonSentence; // AI가 생성하는 비교 문장 (예시)

  const ExpertReading({
    required this.label,
    required this.stance,
    required this.claims,
    required this.fullText,
    required this.comparisonSentence,
  });

  /// 모든 근거 행들의 집합
  Set<int> get allLines {
    final set = <int>{};
    for (final claim in claims) {
      set.addAll(claim.lines);
    }
    return set;
  }

  /// 기획서 4장에 따른 관계 판정 로직 (코드가 계산)
  /// - 같은 행을 근거로 삼음: "같은 곳을 봤어요"
  /// - 근거 행이 일부만 겹침: "같은 줄에서 출발했어요"
  /// - 다른 행을 근거로 삼음: "이 해석은 N행을 중심으로 읽었어요"
  String calculateRelationship(List<int> userLines) {
    if (userLines.isEmpty) {
      final expertLineStr = allLines.toList()..sort();
      return '이 해석은 ${expertLineStr.join(', ')}행을 중심으로 읽었어요';
    }

    final userSet = userLines.toSet();
    final expertSet = allLines;
    final intersection = userSet.intersection(expertSet);

    if (intersection.isNotEmpty) {
      // 완전히 일치하거나 모든 전문가 행을 포함하는 경우
      if (intersection.length == expertSet.length || intersection.length == userSet.length) {
        return '같은 곳을 봤어요';
      }
      // 일부만 겹치는 경우
      return '같은 줄에서 출발했어요';
    } else {
      final sortedLines = expertSet.toList()..sort();
      return '이 해석은 ${sortedLines.join(', ')}행을 중심으로 읽었어요';
    }
  }
}
