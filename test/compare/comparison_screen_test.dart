// 주인: D — S07이 관계를 화면에 어떻게 내보내는지 (기획서 4장)
// computeRelation은 따로 테스트한다. 여기서는 그 결과가 화면 문구로
// 제대로 나오는지만 본다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yeobaek/app/language.dart';
import 'package:yeobaek/app/strings.dart';
import 'package:yeobaek/data/fakes/fake_data.dart';
import 'package:yeobaek/data/models/expert_interpretation.dart';
import 'package:yeobaek/data/models/reading.dart';
import 'package:yeobaek/features/compare/comparison_screen.dart';

import '../support/pump.dart';
import '../support/stub_reading_source.dart';

/// 근거 10행만 가진 전문가 해석
const expertAtLine10 = ExpertInterpretation(
  label: '전문가 해석 T',
  stance: '테스트용 입장',
  claims: [Claim(lines: [10], point: '주장')],
);

void main() {
  /// 수록된 서시 데이터를 주입해서 연다. 에셋 I/O는 위젯 테스트에서 진행되지
  /// 않으므로(support/pump.dart 참고) 소스를 끼운다. 값은 수록된 것 그대로다.
  Future<void> openSeosi(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ComparisonScreen(
          poemId: 'seosi',
          source: StubReadingSource(
            readings: {'seosi': FakeData.myReadings['seosi']!},
            experts: {'seosi': FakeData.expertInterpretations['seosi']!},
            comparisonTexts: {'seosi': FakeData.comparisonTexts['seosi']!},
          ),
        ),
      ),
    );
    await pumpUntilLoaded(tester);
  }

  testWidgets('서시 — 전문가 A는 「같은 줄에서 출발했어요」', (tester) async {
    await openSeosi(tester);

    // 내 근거 [6] 대 전문가 A 근거 [2,6,7,8] → partialOverlap
    expect(
      find.text(AppStrings.comparisonRelationPartialOverlap),
      findsOneWidget,
    );
    // 고치기 전에는 여기가 「같은 곳을 봤어요」였다
    expect(find.text(AppStrings.comparisonRelationSameLines), findsNothing);
  });

  testWidgets('서시 — 전문가 B는 10행을 중심으로 읽었다고 나온다', (tester) async {
    await openSeosi(tester);

    expect(
      find.text(AppStrings.comparisonRelationDifferentLines(const [10])),
      findsOneWidget,
    );
  });

  // 전문가 카드의 「같은 줄에서 출발했어요」가 가리킬 곳이 화면에 있어야 한다.
  // 「내 해석」이라고만 적혀 있으면 무엇과 같은 줄인지 알 수 없다 (2026-11-25 피드백).
  testWidgets('내 카드 꼬리표가 내가 출발한 줄을 말한다', (tester) async {
    await openSeosi(tester);

    // 서시 내 근거는 6행이다
    expect(find.text('내가 출발한 줄: 6행'), findsOneWidget);
    // 관계 한 줄과 같은 말(줄 · 출발)로 짝이 맞는다
    expect(
      find.text(AppStrings.comparisonRelationPartialOverlap),
      findsOneWidget,
    );
    // 시 정보 카드에 있던 같은 말은 빠졌다
    expect(find.textContaining('내 근거'), findsNothing);
  });

  testWidgets('고른 줄이 없으면 줄 대신 해석이라고 말한다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ComparisonScreen(
          poemId: 'seosi',
          source: StubReadingSource(
            // evidenceLines가 비어 있는 읽기
            readings: const {
              'seosi': Reading(poemId: 'seosi', interpretation: '내가 쓴 것'),
            },
            experts: {'seosi': FakeData.expertInterpretations['seosi']!},
          ),
        ),
      ),
    );
    await pumpUntilLoaded(tester);

    expect(find.text(AppStrings.comparisonMine(const [])), findsOneWidget);
    expect(find.textContaining('내가 출발한 줄'), findsNothing);
  });

  testWidgets('EN이면 꼬리표도 영어로 줄을 말한다', (tester) async {
    appLanguage.value = AppLanguage.en;
    addTearDown(() => appLanguage.value = AppLanguage.ko);

    await openSeosi(tester);

    expect(find.text('I started from line 6'), findsOneWidget);
  });

  testWidgets('전문가 해석 둘이 라벨과 함께 나온다', (tester) async {
    await openSeosi(tester);

    expect(find.text('전문가 해석 A'), findsOneWidget);
    expect(find.text('전문가 해석 B'), findsOneWidget);
  });

  testWidgets('해석이 아직 없는 시는 「준비 중」', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ComparisonScreen(
          poemId: 'bomgoyangi',
          source: StubReadingSource(), // experts 비어 있음
        ),
      ),
    );
    await pumpUntilLoaded(tester);

    expect(find.text(AppStrings.comparisonNoExperts), findsOneWidget);
  });

  testWidgets('미리 쓴 비교 문장이 없어도 관계 한 줄은 나온다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ComparisonScreen(
          poemId: 'seosi',
          source: StubReadingSource(
            readings: {'seosi': FakeData.myReadings['seosi']!},
            experts: const {'seosi': [expertAtLine10]},
            // comparisonTexts를 주지 않는다 → 폴백이 관계 한 줄을 채운다
          ),
        ),
      ),
    );
    await pumpUntilLoaded(tester);

    expect(
      find.text(AppStrings.comparisonRelationDifferentLines(const [10])),
      findsOneWidget,
    );
  });
}
