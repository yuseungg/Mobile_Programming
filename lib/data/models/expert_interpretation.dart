// 주인: C · 용어: docs/여백-네이밍규칙.md 2장 「대조」
// 형식: docs/여백-기획서최종.md 7장 「전문가 해석 형식」

class ExpertInterpretation {
  const ExpertInterpretation({
    required this.label,
    required this.stance,
    required this.claims,
  });

  final String label; // "전문가 해석 A" — 특정 인물 이름을 쓰지 않는다
  final String stance; // 입장
  final List<Claim> claims;
}

class Claim {
  const Claim({required this.lines, required this.point});

  final List<int> lines; // 근거 행 번호 (1부터)
  final String point; // 주장 내용
}

/// 내 해석과 전문가 해석의 관계 — 근거 행 겹침으로 코드가 계산한다 (기획서 4장)
enum Relation {
  sameLines, // 같은 곳을 봤어요
  partialOverlap, // 같은 줄에서 출발했어요
  differentLines, // 이 해석은 N행을 중심으로 읽었어요
}
