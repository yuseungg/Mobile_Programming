// 근거 행 · 가리키는 행 (A) — 기획서 F3 「시 고정 표시」
import 'package:flutter_test/flutter_test.dart';
import 'package:yeobaek/agent/line_marks.dart';
import 'package:yeobaek/agent/tools/search_poem_lines.dart';
import 'package:yeobaek/agent/tools/verify_quote.dart';
import 'package:yeobaek/data/fakes/fake_data.dart';

void main() {
  final seosi = FakeData.poemById('seosi');

  test('없는 구절이면 근거 행은 없고, 응답이 짚은 첫 행을 가리킨다 (시연 시나리오)', () {
    final marks = resolveLineMarks(
      poem: seosi,
      userText: "'별을 그리워하며'라는 구절 때문에 그렇게 느꼈어요.",
      quoteChecks: [verifyQuote(seosi, '별을 그리워하며')],
      searches: [searchPoemLines(seosi, '별')],
      replyText: "그 표현은 이 시에 없어요. '별'이 나오는 건 5행과 10행인데, 둘 중 어느 쪽이었을까요?",
    );
    expect(marks.evidenceLines, isEmpty);
    expect(marks.pointingLine, 5);
  });

  test('사용자가 든 구절이 원문에서 확인되면 근거 행이 된다', () {
    final marks = resolveLineMarks(
      poem: seosi,
      userText: "'모든 죽어가는 것을 사랑해야지'가 마음에 남아요.",
      quoteChecks: [verifyQuote(seosi, '모든 죽어가는 것을 사랑해야지')],
      searches: const [],
      replyText: '그 구절에서 어떤 말이 가장 오래 남았나요?',
    );
    expect(marks.evidenceLines, [6]);
    expect(marks.pointingLine, isNull);
  });

  test('사용자가 "N행"으로 짚은 행을 확인하면 근거 행이 된다', () {
    final marks = resolveLineMarks(
      poem: seosi,
      userText: '6행이 더 마음에 남아요.',
      quoteChecks: [verifyQuote(seosi, seosi.lineAt(6))],
      searches: const [],
      replyText: '그 행의 어떤 말이 그렇게 느끼게 했나요?',
    );
    expect(marks.evidenceLines, [6]);
  });

  test('AI가 스스로 확인한 구절은 근거 행이 아니라 가리키는 행이 된다', () {
    final marks = resolveLineMarks(
      poem: seosi,
      userText: '잘 모르겠어요.',
      quoteChecks: [verifyQuote(seosi, '잎새에 이는 바람에도')],
      searches: const [],
      replyText: '바람이 처음 나오는 그 줄에서 무엇이 움직이나요?',
    );
    expect(marks.evidenceLines, isEmpty);
    expect(marks.pointingLine, 3);
  });

  test('시에 없는 행 번호(빈 줄 · 범위 밖)는 가리키지 않는다', () {
    final marks = resolveLineMarks(
      poem: seosi,
      userText: '',
      quoteChecks: const [],
      searches: const [],
      replyText: '9행과 12행을 같이 볼까요?',
    );
    expect(marks.pointingLine, isNull);
  });
}
