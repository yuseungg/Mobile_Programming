// 테스트에서 FutureBuilder가 끝날 때까지 미는 helper.
//
// D 화면들은 읽는 동안 CircularProgressIndicator를 보여 준다. 그것은 끝나지
// 않는 애니메이션이라, 스피너가 화면에 남아 있는 동안 pumpAndSettle은 시간
// 초과된다. 가짜 소스가 즉시 끝나면 우연히 통과하고 에셋을 읽으면 실패하는,
// 깨지기 쉬운 테스트가 된다. 그래서 스피너가 사라질 때까지 명시적으로 민다.
//
// 주의: pump()는 가짜 비동기 구역에서 돌아 **실제 에셋 I/O가 진행되지 않는다.**
// 그래서 위젯 테스트에서 rootBundle을 타는 소스(FakeReadingSource.expertsFor)를
// 쓰면 로딩이 끝나지 않는다. 화면 테스트는 데이터를 주입하고, 에셋 읽기 자체는
// test/compare/expert_parser_test.dart가 실제 번들로 검증한다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yeobaek/shared/widgets/app_loading.dart';

/// 기다릴 로딩 표시들. AppLoading으로 갈아 끼운 화면도 여기서 함께 기다린다 —
/// 스피너만 보면, 스피너를 뺀 화면에서 이 helper가 **첫 프레임에 바로
/// 돌아와** 데이터가 오기 전의 화면을 검사하게 된다.
bool _isLoadingVisible() =>
    find.byType(CircularProgressIndicator).evaluate().isNotEmpty ||
    find.byType(AppLoading).evaluate().isNotEmpty;

Future<void> pumpUntilLoaded(WidgetTester tester, {int tries = 60}) async {
  for (var i = 0; i < tries; i++) {
    await tester.pump(const Duration(milliseconds: 20));
    if (!_isLoadingVisible()) return;
  }
  throw StateError('로딩이 끝나지 않았다');
}
