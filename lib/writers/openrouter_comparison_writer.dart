// 주인: D — 비교 문장을 모델에게 쓰게 하는 구현 (요건 (a) 둘째 화면, 기획서 4장)
//
// S05의 에이전트(A)와 다른 점:
//  - 툴을 쓰지 않는다. 비교에 필요한 재료는 코드가 이미 다 모아 넘긴다.
//  - 관계를 모델에게 묻지 않는다. 코드가 정한 관계를 프롬프트에 박아 넣는다
//    (lib/compare/relation.dart). 모델은 그 관계를 문장으로 옮기기만 한다.
//  - 검사가 다르다. 비교 문장은 질문이 아니라 서술이다 (comparison_guard.dart).
//
// 실패하면 예외를 던지지 않고 [fallback]에게 넘긴다. 대조 화면이 빈 칸으로
// 남는 것이 가장 나쁘다 (기획서 9장 「오프라인·실패 처리」).
// 넘기는 경우: 키 없음 · 호출 실패 · 취소 · 다시 써도 검사를 통과하지 못함.

import 'package:flutter/foundation.dart';

import '../agent/openrouter_client.dart';
import '../data/models/settings.dart';
import '../data/repositories.dart';
import 'comparison_guard.dart';
import 'comparison_prompt.dart';
import 'comparison_writer.dart';

class OpenRouterComparisonWriter implements ComparisonWriter {
  OpenRouterComparisonWriter({
    required this.client,
    required this.model,
    required this.fallback,
    this.tone = Tone.plain,
    this.onModelCall,
  });

  /// 검사에 걸렸을 때 다시 쓰게 하는 횟수. S05(2회)보다 적다 —
  /// 비교 문장은 한 화면에 전문가 수만큼 쓰이므로 호출이 금방 불어난다.
  static const maxRewrites = 1;

  final OpenRouterClient client;
  final String model; // 비교 모델 — 설정(S10 · S11)의 comparisonModel
  final Tone tone;

  /// 모델이 못 썼을 때 대신 채우는 쪽 (미리 쓴 문장 → 관계 한 줄)
  final ComparisonWriter fallback;

  /// 모델을 한 번 부를 때마다. 설정 화면의 이번 달 사용량(비교).
  final Future<void> Function()? onModelCall;

  @override
  Future<ComparisonText> write(ComparisonRequest request) async {
    try {
      final messages = buildComparisonMessages(request: request, tone: tone);
      var text = '';
      var violations = const <ComparisonViolation>[];

      for (var attempt = 0; attempt <= maxRewrites; attempt++) {
        if (attempt > 0) {
          messages.addAll([
            if (text.isNotEmpty) {'role': 'assistant', 'content': text},
            {
              'role': 'user',
              'content': comparisonRewriteInstruction(violations),
            },
          ]);
        }
        _countModelCall();
        final completion = await client.complete(
          model: model,
          messages: messages,
          toolChoice: 'none',
        );
        final failure = completion.failure;
        if (failure != null) return await _giveUp(request, '$failure');

        text = ComparisonGuard.clean(completion.content ?? '');
        violations = ComparisonGuard.check(text, request);
        if (violations.isEmpty) return ComparisonText(text);
      }

      final reasons = violations.map(comparisonViolationReason).join(', ');
      return await _giveUp(request, '검사 — $reasons');
    } catch (error) {
      return _giveUp(request, '$error');
    }
  }

  Future<ComparisonText> _giveUp(ComparisonRequest request, String reason) {
    debugPrint('[compare] 미리 쓴 문장으로 대신함 (${request.expert.label}): $reason');
    return fallback.write(request);
  }

  /// 횟수를 못 세도 대조는 그대로 보여 준다
  void _countModelCall() {
    final count = onModelCall;
    if (count == null) return;
    count().catchError((Object error) {
      debugPrint('[compare] 호출 횟수를 세지 못함: $error');
    });
  }
}

/// 개발 중에 모델을 바꿔 끼울 때: .env(또는 --dart-define)에
/// OPENROUTER_COMPARISON_MODEL=모델 id. 비어 있으면 설정(S10 · S11)의 비교 모델.
/// 비교 문장과 대화 요약이 같은 모델을 쓴다 (기획서 265행).
const comparisonModelOverride =
    String.fromEnvironment('OPENROUTER_COMPARISON_MODEL');

/// 키가 있고 이 플랫폼에서 보낼 수 있으면 모델이 쓰고, 아니면 [fallback]이 쓴다.
/// 설정을 읽지 못하면 모델을 부르지 않는다 — 어떤 모델을 부를지 모르는 채로
/// 무료 한도를 쓰는 것보다 미리 쓴 문장이 낫다.
Future<ComparisonWriter> createComparisonWriter({
  required ComparisonWriter fallback,
}) async {
  final client = OpenRouterClient();
  if (!client.isAvailable) return fallback;
  try {
    final settings = await Repositories.settings.load();
    return OpenRouterComparisonWriter(
      client: client,
      model: comparisonModelOverride.isEmpty
          ? settings.comparisonModel
          : comparisonModelOverride,
      tone: settings.tone,
      fallback: fallback,
      onModelCall: Repositories.settings.countComparisonCall,
    );
  } catch (error) {
    debugPrint('[compare] 설정을 읽지 못해 미리 쓴 문장으로 간다: $error');
    return fallback;
  }
}
