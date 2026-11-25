// 주인: B — S06 초안을 모델이 내 말만 가지고 다듬음 (#64)
// 모델 초안은 그대로 저장 못 하고 고쳐야 저장됨. 못 쓰거나 늦으면 모은 말 그대로
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeobaek/app/strings.dart';
import 'package:yeobaek/data/repositories.dart';
import 'package:yeobaek/features/save/save_screen.dart';
import 'package:yeobaek/writers/summary_writer.dart';

// 정해 둔 글 돌려주는 초안 작성기. 뭘 받았는지도 남김
class _DraftWriter implements SummaryWriter {
  _DraftWriter(this.text, {this.isFallback = false, this.delay = Duration.zero});

  final String text;
  final bool isFallback;
  final Duration delay;
  SummaryRequest? got;

  @override
  Future<SummaryText> write(SummaryRequest request) async {
    got = request;
    await Future<void>.delayed(delay);
    return SummaryText(text, isFallback: isFallback);
  }
}

void main() {
  // 진달래꽃 가짜 기록에서 내가 한 말은 이거 하나
  const myWords = '떠나는 건 님이고 남는 건 나 같아요.';

  setUp(() {
    Repositories.useFakes();
    SharedPreferences.setMockInitialValues({});
  });

  Widget saveApp(SummaryWriter writer, {String poemId = 'jindallae'}) {
    return MaterialApp(home: SaveScreen(poemId: poemId, draftWriter: writer));
  }

  String fieldText(WidgetTester tester) {
    TextField field = tester.widget(find.byType(TextField));
    return field.controller!.text;
  }

  VoidCallback? saveTap(WidgetTester tester) {
    FilledButton button = tester.widget(find.widgetWithText(FilledButton, AppStrings.saveButton));
    return button.onPressed;
  }

  testWidgets('모델 초안이 칸에 들어오고, 그대로는 저장 못 하고 고치면 저장됨', (tester) async {
    _DraftWriter writer = _DraftWriter('나는 떠나는 건 님이고 남는 건 나라고 봤어요.');
    await tester.pumpWidget(saveApp(writer));
    await tester.pumpAndSettle();

    expect(writer.got!.conversation, isNotEmpty);
    expect(writer.got!.interpretation, ''); // 아직 해석 없음
    expect(fieldText(tester), '나는 떠나는 건 님이고 남는 건 나라고 봤어요.');
    expect(find.text(AppStrings.saveDraftWrittenNotice), findsOneWidget);
    expect(saveTap(tester), isNull);

    await tester.enterText(find.byType(TextField), '떠나는 건 님이고 남는 건 나다.');
    await tester.pump();
    expect(saveTap(tester), isNotNull);
  });

  testWidgets('초안 쓰는 동안은 진행 막대 뜨고 칸 · 저장 막힘, 그동안 모은 말 보임', (tester) async {
    _DraftWriter writer = _DraftWriter('초안', delay: const Duration(seconds: 3));
    await tester.pumpWidget(saveApp(writer));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text(AppStrings.saveDrafting), findsOneWidget);
    TextField field = tester.widget(find.byType(TextField));
    expect(field.readOnly, true);
    expect(saveTap(tester), isNull);
    expect(fieldText(tester), myWords);

    await tester.pump(const Duration(seconds: 3));
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(fieldText(tester), '초안');
  });

  testWidgets('모델이 못 쓰면(isFallback) 모은 말 그대로 두고 바로 저장 가능', (tester) async {
    await tester.pumpWidget(saveApp(_DraftWriter('사실 문장', isFallback: true)));
    await tester.pumpAndSettle();

    expect(fieldText(tester), myWords);
    expect(find.text(AppStrings.saveDraftNotice), findsOneWidget);
    expect(saveTap(tester), isNotNull);
  });

  testWidgets('20초 넘으면 안 기다리고 모은 말 그대로', (tester) async {
    await tester.pumpWidget(saveApp(_DraftWriter('늦은 초안', delay: const Duration(seconds: 30))));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 21));

    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(fieldText(tester), myWords);
    expect(saveTap(tester), isNotNull);

    // 늦게 온 초안이 고치던 칸을 덮으면 안 됨
    await tester.pump(const Duration(seconds: 10));
    expect(fieldText(tester), myWords);
  });

  testWidgets('이미 저장한 시는 초안 안 씀', (tester) async {
    _DraftWriter writer = _DraftWriter('초안');
    await tester.pumpWidget(saveApp(writer, poemId: 'seosi'));
    await tester.pumpAndSettle();

    expect(writer.got, isNull);
    expect(fieldText(tester), startsWith('부끄러움을 아는 사람이'));
  });
}
