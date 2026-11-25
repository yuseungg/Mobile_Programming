// 모든 테스트 파일 앞에 flutter test가 자동으로 부른다.
//
// 앱은 처음 켜면 영어로 시작한다 (lib/app/language.dart — 교수님 공지).
// 기존 테스트는 한국어 문구로 화면을 찾으므로, 테스트마다 한국어로 시작하게 둔다.
// 영어를 보는 테스트는 그 안에서 appLanguage.value = AppLanguage.en으로 바꾼다.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yeobaek/app/language.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // 테스트 파일이 main()에서 미리 만들어 두는 기대 문구도 한국어로 (setUp보다 먼저 돈다)
  appLanguage.value = AppLanguage.ko;
  // 앞 테스트가 영어로 바꿔 두고 끝나도 다음 테스트는 한국어로
  setUp(() => appLanguage.value = AppLanguage.ko);
  await testMain();
}
