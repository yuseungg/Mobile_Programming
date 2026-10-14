// 주인: A — 플랫폼에 맞는 HTTP 구현을 고른다
// Android · Windows · 테스트는 dart:io로 보낸다.
// 웹은 dart:io가 없어 아직 보내지 못한다 → 가짜 에이전트가 붙는다. http 패키지가 들어오면 바꾼다.
export 'http_post_stub.dart' if (dart.library.io) 'http_post_io.dart';
