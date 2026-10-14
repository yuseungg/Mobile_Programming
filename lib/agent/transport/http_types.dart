// 주인: A — 플랫폼별 HTTP 구현이 같이 쓰는 모양
import '../cancel_token.dart';

class HttpResponseData {
  const HttpResponseData({required this.statusCode, required this.body});

  final int statusCode;
  final String body;
}

/// JSON 본문을 POST하고 응답 본문을 문자열로 돌려준다. 실패하면 예외를 던진다.
typedef PostJson = Future<HttpResponseData> Function(
  Uri uri, {
  required Map<String, String> headers,
  required String body,
  required Duration timeout,
  CancelToken? cancelToken,
});
