// 주인: C — 테스트에서 S01을 지나가는 법 (S01이 진짜 로그인을 하므로 칸을 채워야 한다)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yeobaek/app/strings.dart';
import 'package:yeobaek/data/fakes/fake_auth_repository.dart';

/// S01에서 데모 계정(가짜 저장소)으로 로그인 버튼까지 누른다. 다음 화면은 S13 안내다.
Future<void> signInAsDemo(WidgetTester tester) async {
  final fields = find.byType(TextField);
  await tester.enterText(fields.at(0), FakeAuthRepository.demoEmail);
  await tester.enterText(fields.at(1), FakeAuthRepository.demoPassword);
  await tester.pump();

  final button = find.widgetWithText(FilledButton, AppStrings.signInButton);
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}
