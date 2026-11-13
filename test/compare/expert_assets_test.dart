// 주인: D — assets/poems/*.json 실물 검사
// 기준: docs/여백-기획서최종.md 7장 「전문가 해석 형식」, 4장 「관계 표」
//
// 파서 단위 테스트(expert_parser_test.dart)는 문자열만 본다. 여기서는
// 실제로 앱에 들어가는 파일을 읽어, 시연에서 깨질 수 있는 것 둘을 막는다.
//   1) 근거 행 번호가 시 행 수를 넘는 것 — 파서는 상한을 모른다.
//   2) 「같은 곳을 봤어요」가 영구히 안 나오는 것 — computeRelation은 내 근거를
//      전문가의 근거 행 **전체**와 비교하므로, 근거 행이 하나인 해석이 한 편에
//      하나도 없으면 그 판정에 도달할 길이 없다.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yeobaek/compare/expert_parser.dart';
import 'package:yeobaek/compare/relation.dart';
import 'package:yeobaek/data/fakes/fake_data.dart';
import 'package:yeobaek/data/models/expert_interpretation.dart';

void main() {
  final poemIds = FakeData.poems.map((p) => p.poemId).toList();

  group('assets/poems 실물', () {
    for (final poemId in poemIds) {
      group(poemId, () {
        final path = 'assets/poems/$poemId.json';
        final file = File(path);

        test('파일이 있고 형식이 맞다', () {
          expect(file.existsSync(), isTrue, reason: '$path가 없다');
          final parsed = parseExpertFile(file.readAsStringSync());
          expect(parsed.poemId, poemId, reason: 'poem 값이 파일 이름과 다르다');
          expect(parsed.badgeAssetPath, 'assets/badges/$poemId.png');
          expect(parsed.readings, hasLength(greaterThanOrEqualTo(2)));
        });

        test('근거 행이 시 행 수 안에 있다', () {
          final lineCount = FakeData.poemById(poemId).lines.length;
          final parsed = parseExpertFile(file.readAsStringSync());
          for (final reading in parsed.readings) {
            for (final claim in reading.claims) {
              for (final line in claim.lines) {
                expect(
                  line,
                  inInclusiveRange(1, lineCount),
                  reason: '${reading.label}의 근거 행 $line이 1~$lineCount 밖이다',
                );
              }
            }
          }
        });

        test('「같은 곳을 봤어요」에 도달할 수 있다', () {
          final parsed = parseExpertFile(file.readAsStringSync());
          final reachable = parsed.readings.where(
            (r) => expertLines(r).length == 1,
          );
          expect(
            reachable,
            isNotEmpty,
            reason: '근거 행이 하나인 해석이 없어 sameLines가 나올 수 없다',
          );
          for (final reading in reachable) {
            expect(
              computeRelation(expertLines(reading), reading),
              Relation.sameLines,
            );
          }
        });

        test('빈 줄을 근거로 삼지 않는다', () {
          final lines = FakeData.poemById(poemId).lines;
          final parsed = parseExpertFile(file.readAsStringSync());
          for (final reading in parsed.readings) {
            for (final claim in reading.claims) {
              for (final line in claim.lines) {
                expect(
                  lines[line - 1].trim(),
                  isNotEmpty,
                  reason: '${reading.label}이 빈 줄($line행)을 근거로 삼았다',
                );
              }
            }
          }
        });
      });
    }
  });
}
