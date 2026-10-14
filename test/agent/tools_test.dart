// 툴 verify_quote · search_poem_lines (A) — 기획서 6장
import 'package:flutter_test/flutter_test.dart';
import 'package:yeobaek/agent/tools/search_poem_lines.dart';
import 'package:yeobaek/agent/tools/verify_quote.dart';
import 'package:yeobaek/data/fakes/fake_data.dart';

void main() {
  final seosi = FakeData.poemById('seosi');

  group('verify_quote', () {
    test('원문에 없는 구절은 찾지 못한다 (시연 시나리오)', () {
      final check = verifyQuote(seosi, '별을 그리워하며');
      expect(check.isFound, isFalse);
      expect(check.toJson(), {'found': false, 'quote': '별을 그리워하며'});
    });

    test('있는 구절은 1부터 센 행 번호를 돌려준다', () {
      expect(verifyQuote(seosi, '모든 죽어가는 것을 사랑해야지').lineNos, [6]);
    });

    test('연 구분 빈 줄도 번호를 하나 차지한다 — 서시의 마지막 행은 10행', () {
      expect(verifyQuote(seosi, '오늘 밤에도 별이 바람에 스치운다').lineNos, [10]);
    });

    test('따옴표와 끝 문장부호는 떼고 찾는다', () {
      expect(verifyQuote(seosi, "'한 점 부끄럼이 없기를'").lineNos, [2]);
      expect(verifyQuote(seosi, '걸어가야겠다.').lineNos, [8]);
    });

    test('행을 넘어가는 구절도 찾는다', () {
      expect(verifyQuote(seosi, '주어진 길을 걸어가야겠다').lineNos, [7, 8]);
    });

    test('빈 구절은 찾지 못한다', () {
      expect(verifyQuote(seosi, " '' ").isFound, isFalse);
    });
  });

  group('search_poem_lines', () {
    test("'별'은 5행과 10행에 나온다", () {
      final lineNos = [for (final match in searchPoemLines(seosi, '별')) match.lineNo];
      expect(lineNos, [5, 10]);
    });

    test('행 번호와 행을 함께 돌려준다', () {
      expect(
        searchPoemLines(seosi, '바람').first.toJson(),
        {'lineNo': 3, 'line': '잎새에 이는 바람에도'},
      );
    });

    test('빈 낱말은 아무것도 찾지 않는다', () {
      expect(searchPoemLines(seosi, '  '), isEmpty);
    });
  });
}
