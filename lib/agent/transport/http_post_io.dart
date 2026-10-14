// 주인: A — dart:io로 보내는 HTTP (Android · Windows · 테스트)
import 'dart:convert';
import 'dart:io';

import '../cancel_token.dart';
import 'http_types.dart';

const isHttpSupported = true;

Future<HttpResponseData> postJson(
  Uri uri, {
  required Map<String, String> headers,
  required String body,
  required Duration timeout,
  CancelToken? cancelToken,
}) async {
  final client = HttpClient()..connectionTimeout = timeout;
  try {
    final request = await client.postUrl(uri).timeout(timeout);
    for (final header in headers.entries) {
      request.headers.set(header.key, header.value);
    }
    request.headers.contentType =
        ContentType('application', 'json', charset: 'utf-8');
    request.add(utf8.encode(body));

    // 중단 버튼을 누르면 보내던 요청을 끊는다
    void abort() => request.abort();
    cancelToken?.addListener(abort);
    try {
      final response = await request.close().timeout(timeout);
      final text =
          await response.transform(utf8.decoder).join().timeout(timeout);
      return HttpResponseData(statusCode: response.statusCode, body: text);
    } finally {
      cancelToken?.removeListener(abort);
    }
  } finally {
    client.close(force: true);
  }
}
