// 주인: D — lib/compare/expert_parser.dart 단위 테스트
// 기준: docs/여백-기획서최종.md 7장 「전문가 해석 형식」

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yeobaek/compare/expert_parser.dart';
import 'package:yeobaek/compare/relation.dart';
import 'package:yeobaek/data/models/expert_interpretation.dart';

const _valid = '''
{
  "poem": "seosi",
  "badge": "badges/seosi.png",
  "readings": [
    {
      "label": "전문가 해석 A",
      "stance": "부끄러움과 다짐으로 읽는 입장",
      "claims": [
        { "lines": [2], "point": "도달할 수 없는 기준이다" },
        { "lines": [6, 7, 8], "point": "괴로움을 통과한 뒤의 다짐이다" }
      ]
    },
    {
      "label": "전문가 해석 B",
      "stance": "시대 앞의 무력감으로 읽는 입장",
      "claims": [
        { "lines": [10], "point": "밤은 그대로 온다" }
      ]
    }
  ]
}
''';

void main() {
  group('parseExpertFile — 제대로 된 파일', () {
    test('시 id와 뱃지 경로를 읽는다', () {
      final file = parseExpertFile(_valid);
      expect(file.poemId, 'seosi');
      expect(file.badgePath, 'badges/seosi.png');
      expect(file.badgeAssetPath, 'assets/badges/seosi.png');
    });

    test('해석과 주장을 순서대로 읽는다', () {
      final file = parseExpertFile(_valid);
      expect(file.readings, hasLength(2));
      expect(file.readings[0].label, '전문가 해석 A');
      expect(file.readings[0].claims, hasLength(2));
      expect(file.readings[0].claims[1].lines, [6, 7, 8]);
      expect(file.readings[1].stance, '시대 앞의 무력감으로 읽는 입장');
    });

    test('읽은 결과로 관계 계산이 바로 된다', () {
      final file = parseExpertFile(_valid);
      expect(expertLines(file.readings[0]), [2, 6, 7, 8]);
      expect(computeRelation([6], file.readings[0]), Relation.partialOverlap);
      expect(computeRelation([6], file.readings[1]), Relation.differentLines);
    });
  });

  group('parseExpertFile — 어긋난 파일은 던진다', () {
    test('최상위가 객체가 아니면', () {
      expect(() => parseExpertFile('[]'), throwsFormatException);
    });

    test('poem이 비어 있으면', () {
      expect(
        () => parseExpertFile('{"poem":"  ","badge":"b.png","readings":[]}'),
        throwsFormatException,
      );
    });

    test('badge가 없으면', () {
      expect(
        () => parseExpertFile('{"poem":"seosi","readings":[]}'),
        throwsFormatException,
      );
    });

    test('readings가 배열이 아니면', () {
      expect(
        () => parseExpertFile('{"poem":"s","badge":"b","readings":{}}'),
        throwsFormatException,
      );
    });

    test('주장에 근거 행이 없으면 — 관계를 계산할 수 없다', () {
      const noLines = '''
      {"poem":"s","badge":"b","readings":[
        {"label":"A","stance":"입장","claims":[{"point":"근거 없는 주장"}]}
      ]}
      ''';
      expect(() => parseExpertFile(noLines), throwsFormatException);
    });

    test('근거 행이 0이나 음수면 — 행 번호는 1부터', () {
      const zeroLine = '''
      {"poem":"s","badge":"b","readings":[
        {"label":"A","stance":"입장","claims":[{"lines":[0],"point":"주장"}]}
      ]}
      ''';
      expect(() => parseExpertFile(zeroLine), throwsFormatException);
    });

    test('claims가 비어 있으면', () {
      const noClaims = '''
      {"poem":"s","badge":"b","readings":[
        {"label":"A","stance":"입장","claims":[]}
      ]}
      ''';
      expect(() => parseExpertFile(noClaims), throwsFormatException);
    });

    test('JSON 자체가 깨졌으면', () {
      expect(() => parseExpertFile('{'), throwsFormatException);
    });
  });

  group('loadExpertFile — 에셋에서 읽기', () {
    test('수록된 서시 파일을 읽는다', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final file = await loadExpertFile('seosi');
      expect(file, isNotNull);
      expect(file!.poemId, 'seosi');
      // 기획서: 전문가 해석은 시마다 둘 이상, 서로 입장이 달라야 한다.
      expect(file.readings.length, greaterThanOrEqualTo(2));
      expect(file.readings[0].stance, isNot(file.readings[1].stance));
    });

    test('아직 해석을 쓰지 않은 시는 null — 오류가 아니다', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      expect(await loadExpertFile('jindallae'), isNull);
      expect(await loadExpertFile('bomgoyangi'), isNull);
    });

    test('경로 규칙', () {
      expect(expertAssetPath('seosi'), 'assets/poems/seosi.json');
    });

    test('넘겨준 번들에서 읽는다', () async {
      final bundle = TestAssetBundle({'assets/poems/x.json': _valid});
      final file = await loadExpertFile('x', bundle: bundle);
      expect(file!.readings, hasLength(2));
    });
  });
}

/// 테스트용 에셋 번들 — 경로에 없는 것은 FlutterError를 던진다 (실제 번들과 같게)
class TestAssetBundle extends CachingAssetBundle {
  TestAssetBundle(this.files);

  final Map<String, String> files;

  @override
  Future<ByteData> load(String key) async {
    final source = files[key];
    if (source == null) throw FlutterError('없는 에셋: $key');
    final bytes = Uint8List.fromList(source.codeUnits);
    return ByteData.view(bytes.buffer);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final source = files[key];
    if (source == null) throw FlutterError('없는 에셋: $key');
    return source;
  }
}
