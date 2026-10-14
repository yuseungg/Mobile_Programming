// 주인: A — OpenRouter 클라이언트 (D도 가져다 쓴다)
// 키는 --dart-define(또는 --dart-define-from-file=.env)의 OPENROUTER_API_KEY로만 받는다. 코드에 쓰지 않는다.
//
// D와의 약속 (코딩분업 3장 「A → D」)
// - 모델 이름은 부를 때마다 넘긴다 (Settings.questionModel · comparisonModel).
// - 실패해도 예외를 던지지 않는다. ChatCompletion.failure에 이유를 담아 돌려준다.
//   HTTP 200이어도 본문에 error가 오면 실패로 본다 (무료 모델에서 실제로 생긴다).
import 'dart:convert';

import 'cancel_token.dart';
import 'transport/http_post.dart' as platform;
import 'transport/http_types.dart';

class OpenRouterClient {
  OpenRouterClient({
    String? apiKey,
    PostJson? postJson,
    this.timeout = const Duration(seconds: 60),
  })  : apiKey = apiKey ?? const String.fromEnvironment('OPENROUTER_API_KEY'),
        _postJson = postJson ?? platform.postJson,
        _canPost = postJson != null || platform.isHttpSupported;

  static final _endpoint =
      Uri.parse('https://openrouter.ai/api/v1/chat/completions');

  final String apiKey;
  final Duration timeout;
  final PostJson _postJson;
  final bool _canPost;

  /// 키가 있고, 이 플랫폼에서 요청을 보낼 수 있는가 (웹은 아직 못 보낸다)
  bool get isAvailable => apiKey.isNotEmpty && _canPost;

  /// 채팅 완성 한 번. [toolChoice]에 'none'을 주면 툴 없이 답하게 한다.
  Future<ChatCompletion> complete({
    required String model,
    required List<Map<String, Object?>> messages,
    List<Map<String, Object?>>? tools,
    String? toolChoice,
    CancelToken? cancelToken,
  }) async {
    if (cancelToken?.isCancelled ?? false) {
      return const ChatCompletion.failed(OpenRouterFailure.cancelled());
    }
    try {
      final response = await _postJson(
        _endpoint,
        headers: {'Authorization': 'Bearer $apiKey'},
        body: jsonEncode({
          'model': model,
          'messages': messages,
          'tools': ?tools,
          'tool_choice': ?toolChoice,
        }),
        timeout: timeout,
        cancelToken: cancelToken,
      );
      return ChatCompletion.fromResponse(response);
    } catch (error) {
      if (cancelToken?.isCancelled ?? false) {
        return const ChatCompletion.failed(OpenRouterFailure.cancelled());
      }
      return ChatCompletion.failed(OpenRouterFailure(message: '$error'));
    }
  }
}

/// 응답 한 번의 결과. 실패면 [failure]가 있고 나머지는 비어 있다.
class ChatCompletion {
  const ChatCompletion({
    this.content,
    this.toolCalls = const [],
    this.assistantMessage,
  }) : failure = null;

  const ChatCompletion.failed(OpenRouterFailure this.failure)
      : content = null,
        toolCalls = const [],
        assistantMessage = null;

  factory ChatCompletion.fromResponse(HttpResponseData response) {
    final Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      return ChatCompletion.failed(OpenRouterFailure(
        statusCode: response.statusCode,
        message: _head(response.body),
      ));
    }
    if (decoded is! Map) {
      return ChatCompletion.failed(OpenRouterFailure(
        statusCode: response.statusCode,
        message: _head(response.body),
      ));
    }

    final error = decoded['error'];
    if (response.statusCode != 200 || error != null) {
      return ChatCompletion.failed(_failureFrom(response, error));
    }

    final choices = decoded['choices'];
    final firstChoice = choices is List && choices.isNotEmpty ? choices.first : null;
    final message = firstChoice is Map ? firstChoice['message'] : null;
    if (message is! Map) {
      return const ChatCompletion.failed(
        OpenRouterFailure(statusCode: 200, message: '응답에 message가 없다'),
      );
    }

    final content = message['content'];
    final rawToolCalls = message['tool_calls'];
    final toolCalls = [
      if (rawToolCalls is List)
        for (final raw in rawToolCalls)
          if (raw is Map && raw['function'] is Map)
            ToolCall(
              id: '${raw['id'] ?? ''}',
              name: '${(raw['function'] as Map)['name'] ?? ''}',
              arguments: _decodeArguments((raw['function'] as Map)['arguments']),
            ),
    ];
    return ChatCompletion(
      content: content is String ? content : null,
      toolCalls: toolCalls,
      assistantMessage: {
        'role': 'assistant',
        'content': content is String ? content : null,
        if (toolCalls.isNotEmpty) 'tool_calls': rawToolCalls,
      },
    );
  }

  final String? content;
  final List<ToolCall> toolCalls;

  /// 툴을 부른 응답을 다음 요청에 그대로 되돌려 보낼 때 쓰는 assistant 메시지
  final Map<String, Object?>? assistantMessage;
  final OpenRouterFailure? failure;

  bool get isFailure => failure != null;
}

class ToolCall {
  const ToolCall({required this.id, required this.name, required this.arguments});

  final String id;
  final String name;
  final Map<String, Object?> arguments;
}

class OpenRouterFailure {
  const OpenRouterFailure({this.statusCode, required this.message})
      : isCancelled = false;

  const OpenRouterFailure.cancelled()
      : statusCode = null,
        message = '취소됨',
        isCancelled = true;

  final int? statusCode;
  final String message;
  final bool isCancelled; // 중단 버튼으로 멈췄는가

  @override
  String toString() => statusCode == null ? message : '$statusCode $message';
}

OpenRouterFailure _failureFrom(HttpResponseData response, Object? error) {
  if (error is! Map) {
    return OpenRouterFailure(
      statusCode: response.statusCode,
      message: error == null ? _head(response.body) : '$error',
    );
  }
  final code = error['code'];
  final metadata = error['metadata'];
  final detail = metadata is Map ? metadata['raw'] : null;
  return OpenRouterFailure(
    statusCode: code is int ? code : response.statusCode,
    message: detail == null ? '${error['message']}' : '${error['message']} — $detail',
  );
}

Map<String, Object?> _decodeArguments(Object? raw) {
  if (raw is Map) return raw.cast<String, Object?>();
  if (raw is! String || raw.trim().isEmpty) return const {};
  try {
    final decoded = jsonDecode(raw);
    return decoded is Map ? decoded.cast<String, Object?>() : const {};
  } on FormatException {
    return const {};
  }
}

String _head(String text) => text.length > 200 ? '${text.substring(0, 200)}…' : text;
