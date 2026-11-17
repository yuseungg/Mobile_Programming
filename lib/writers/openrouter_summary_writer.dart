// 주인: D — 대화 요약을 모델에게 쓰게 하는 구현 (기획서 F7 「AI 요약」)
//
// 비교 문장(S07)과 같은 모양이지만 두 가지가 다르다.
//
//  1. **대화 원본이 없으면 모델을 부르지 않는다.** 요약은 저장할 때(S06) 한 번
//     쓰여 공개 대화 문서에 담긴다. S09는 그때 못 쓴 요약을 사실만으로 채우는
//     자리이고, 공개 문서에는 대화 원본이 없다(conversation 비어 있음).
//     남의 대화를 열어 볼 때마다 모델이 돌면 안 된다.
//  2. **검사가 더 엄하다** (summary_guard.dart). 남이 읽는 글이다.
//
// 요약 때문에 저장이 실패하면 안 되므로 예외를 던지지 않는다 (기획서 9장).
// 키 없음 · 호출 실패 · 취소 · 검사 탈락은 모두 FakeSummaryWriter로 넘긴다.

import 'package:flutter/foundation.dart';

import '../agent/openrouter_client.dart';
import '../data/models/settings.dart';
import '../data/repositories.dart';
import '../ports/reading_source.dart';
import '../ports/repository_reading_source.dart';
import 'fake_summary_writer.dart';
import 'openrouter_comparison_writer.dart';
import 'summary_guard.dart';
import 'summary_prompt.dart';
import 'summary_writer.dart';

class OpenRouterSummaryWriter implements SummaryWriter {
  OpenRouterSummaryWriter({
    required this.client,
    required this.model,
    required this.fallback,
    this.source = const RepositoryReadingSource(),
    this.tone = Tone.plain,
    this.onModelCall,
  });

  /// 검사에 걸렸을 때 다시 쓰게 하는 횟수. 저장 버튼을 누른 사람을 기다리게
  /// 하는 자리라 길게 끌지 않는다.
  static const maxRewrites = 1;

  final OpenRouterClient client;
  final String model; // 비교 모델 — 설정(S10 · S11)의 comparisonModel
  /// 시 원문을 읽는 곳. 인용 검사와 지시문이 원문을 쓴다 (D의 포트).
  final ReadingSource source;
  final Tone tone;

  /// 모델이 못 썼을 때 대신 채우는 쪽 (첫 낱말과 질문 수만 쓰는 사실 문장)
  final SummaryWriter fallback;

  /// 모델을 한 번 부를 때마다. 설정 화면의 이번 달 사용량(비교).
  final Future<void> Function()? onModelCall;

  @override
  Future<SummaryText> write(SummaryRequest request) async {
    // 대화 원본이 없으면 요약할 재료가 없다 (S09에서 채울 때)
    if (request.conversation.isEmpty) {
      return _giveUp(request, '대화 원본이 없다');
    }

    try {
      final poem = await source.poemById(request.poemId);
      final messages = buildSummaryMessages(
        request: request,
        poem: poem,
        tone: tone,
      );
      var text = '';
      var violations = const <SummaryViolation>[];

      for (var attempt = 0; attempt <= maxRewrites; attempt++) {
        if (attempt > 0) {
          messages.addAll([
            if (text.isNotEmpty) {'role': 'assistant', 'content': text},
            {'role': 'user', 'content': summaryRewriteInstruction(violations)},
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

        text = SummaryGuard.clean(completion.content ?? '');
        violations = SummaryGuard.check(text, request);
        if (violations.isEmpty) return SummaryText(text);
      }

      final reasons = violations.map(summaryViolationReason).join(', ');
      return await _giveUp(request, '검사 — $reasons');
    } catch (error) {
      return _giveUp(request, '$error');
    }
  }

  Future<SummaryText> _giveUp(SummaryRequest request, String reason) {
    debugPrint('[summary] 사실 문장으로 대신함 (${request.poemId}): $reason');
    return fallback.write(request);
  }

  /// 횟수를 못 세도 저장은 그대로 끝낸다
  void _countModelCall() {
    final count = onModelCall;
    if (count == null) return;
    count().catchError((Object error) {
      debugPrint('[summary] 호출 횟수를 세지 못함: $error');
    });
  }
}

/// 키가 있고 이 플랫폼에서 보낼 수 있으면 모델이 쓰고, 아니면 [fallback]이 쓴다.
/// 설정을 읽지 못하면 모델을 부르지 않는다 — 저장을 기다리게 하는 것보다
/// 사실 문장이 낫다.
Future<SummaryWriter> createSummaryWriter({
  SummaryWriter fallback = const FakeSummaryWriter(),
}) async {
  final client = OpenRouterClient();
  if (!client.isAvailable) return fallback;
  try {
    final settings = await Repositories.settings.load();
    return OpenRouterSummaryWriter(
      client: client,
      model: comparisonModelOverride.isEmpty
          ? settings.comparisonModel
          : comparisonModelOverride,
      tone: settings.tone,
      fallback: fallback,
      onModelCall: Repositories.settings.countComparisonCall,
    );
  } catch (error) {
    debugPrint('[summary] 설정을 읽지 못해 사실 문장으로 간다: $error');
    return fallback;
  }
}
