// 주인: A — dart:io가 없는 플랫폼(웹)용 자리 표시
// isHttpSupported가 false라 OpenRouterClient.isAvailable도 false → 가짜 에이전트가 붙는다.
import '../cancel_token.dart';
import 'http_types.dart';

const isHttpSupported = false;

Future<HttpResponseData> postJson(
  Uri uri, {
  required Map<String, String> headers,
  required String body,
  required Duration timeout,
  CancelToken? cancelToken,
}) =>
    throw UnsupportedError('이 플랫폼에서는 OpenRouter에 요청을 보낼 수 없다.');
