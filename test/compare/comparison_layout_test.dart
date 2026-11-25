// 주인: D — S07 화면이 깨지는 자리 (태블릿 점검에서 나왔다)
//
// 전문가 근거 행 칸이 좁아서 「6행, 7행, 8행」이 「8」과 「행」으로 갈렸다.
// 폭을 넓히는 것으로는 「고쳐지지」 않는다. 한글은 글자 단위로 줄이 바뀌므로,
// 칸이 모자라면 폭이 얼마든 또 갈린다. 그래서 행마다 따로 그려 Wrap이 행
// **사이**에서만 줄을 바꾸게 했다. 아래 테스트는 그 구조를 본다.
//
// 같은 점검에서 나온 「근거 행이 없으면 「내 근거:」만 덩그러니 떴다」는 여기서
// 비었을 때만 숨기는 것으로 막았는데, 그 뒤 그 꼬리표 자체를 뺐다 — 내 카드가
// 「내가 출발한 줄: 6행」으로 같은 말을 하고 있었다 (2026-11-25 사용자 피드백).
// 그래서 꼬리표를 보던 테스트는 comparison_screen_test.dart로 옮겨졌다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yeobaek/app/strings.dart';
import 'package:yeobaek/data/fakes/fake_data.dart';
import 'package:yeobaek/data/models/expert_interpretation.dart';
import 'package:yeobaek/data/models/reading.dart';
import 'package:yeobaek/features/compare/comparison_screen.dart';

import '../support/pump.dart';
import '../support/stub_reading_source.dart';

/// 근거가 세 행인 주장 하나 — 좁은 칸에서 갈리던 그 경우다
const expertAtThreeLines = ExpertInterpretation(
  label: '전문가 해석 T',
  stance: '테스트용 입장',
  claims: [
    Claim(lines: [6, 7, 8], point: '세 행을 묶어 읽는 주장'),
  ],
);

void main() {
  Future<void> open(
    WidgetTester tester, {
    required Reading reading,
    ExpertInterpretation expert = expertAtThreeLines,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ComparisonScreen(
          poemId: 'seosi',
          source: StubReadingSource(
            readings: {'seosi': reading},
            experts: {
              'seosi': [expert]
            },
          ),
        ),
      ),
    );
    await pumpUntilLoaded(tester);
  }

  group('전문가 근거 행', () {
    testWidgets('행마다 따로 그린다 — 한 덩어리로 이어 쓰지 않는다', (tester) async {
      await open(
        tester,
        reading: const Reading(
          poemId: 'seosi',
          interpretation: '해석',
          evidenceLines: [6],
          isSaved: true,
        ),
      );

      // 세 행이 각각 제 Text로 있다 → 「8행」 안에서는 줄이 바뀔 수 없다
      for (final lineNo in const [6, 7, 8]) {
        expect(
          find.text(AppStrings.lineLabel(lineNo)),
          findsOneWidget,
          reason: '$lineNo행이 제 Text로 있지 않다',
        );
      }

      // 셋을 이어 붙인 한 덩어리는 없다 (있으면 좁은 칸에서 또 갈린다)
      expect(
        find.text(AppStrings.lineList(const [6, 7, 8])),
        findsNothing,
      );
    });

    testWidgets('좁은 화면에서도 「행」이 숫자에서 떨어지지 않는다', (tester) async {
      // 태블릿보다 좁은 쪽으로 몰아 본다
      tester.view.physicalSize = const Size(320 * 3, 640 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      await open(
        tester,
        reading: const Reading(
          poemId: 'seosi',
          interpretation: '해석',
          evidenceLines: [6],
          isSaved: true,
        ),
      );

      for (final lineNo in const [6, 7, 8]) {
        final text = tester.widget<Text>(
          find.text(AppStrings.lineLabel(lineNo)),
        );
        // 한 Text 안에 숫자와 「행」이 함께 있다. 줄바꿈은 이 Text들 사이에서만
        // 일어나므로 「8」과 「행」이 갈릴 자리가 없다.
        expect(text.data, '$lineNo행');
      }
    });
  });

  testWidgets('수록된 서시 데이터로 열어도 내 카드 꼬리표가 나온다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ComparisonScreen(
          poemId: 'seosi',
          source: StubReadingSource(
            readings: {'seosi': FakeData.myReadings['seosi']!},
            experts: {'seosi': FakeData.expertInterpretations['seosi']!},
          ),
        ),
      ),
    );
    await pumpUntilLoaded(tester);

    // 서시 내 근거는 6행이다. 예전에는 시 정보 카드의 「내 근거: 6행」을 봤다.
    expect(find.text(AppStrings.comparisonMine(const [6])), findsOneWidget);
  });
}
