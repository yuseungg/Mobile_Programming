// 주인: C · 용어: docs/여백-네이밍규칙.md 2장
// 행 번호(lineNo)는 1부터 센다. 배열에서 꺼낼 때만 lines[lineNo - 1].
// 연 구분은 lines 안의 빈 문자열("")이고, 번호를 하나 차지한다.

class Poem {
  const Poem({
    required this.poemId,
    required this.title,
    required this.author,
    required this.year,
    required this.lines,
    required this.creationBackground,
  });

  final String poemId; // 로마자 소문자 · 예: seosi
  final String title;
  final String author;
  final int year;
  final List<String> lines;

  /// 창작 배경 (사실만). `context`라는 이름은 쓰지 않는다.
  final String creationBackground;

  /// 1부터 세는 행 번호로 한 줄을 꺼낸다.
  String lineAt(int lineNo) => lines[lineNo - 1];
}
