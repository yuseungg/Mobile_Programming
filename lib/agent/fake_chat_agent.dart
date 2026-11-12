// 주인: A — 가짜 에이전트 (코딩분업 3장: 고정 응답을 돌려주는 가짜 에이전트)
// 키 없이도 S05 화면 동작과 S05 → S06 흐름을 확인할 수 있다.
// 모델은 부르지 않지만 툴(verify_quote · search_poem_lines)과 근거 행 계산은 진짜를 쓴다.
// 그래서 따옴표로 구절을 인용하거나 "N행"이라고 쓰면 초록 실선 · 회색 점선이 실제로 바뀐다.
import '../data/models/chat_message.dart';
import '../data/models/poem.dart';
import 'cancel_token.dart';
import 'chat_agent.dart';
import 'line_marks.dart';
import 'prompts/fallback_questions.dart';
import 'tools/poem_text.dart';
import 'tools/search_poem_lines.dart';
import 'tools/verify_quote.dart';

class FakeChatAgent implements ChatAgent {
  FakeChatAgent({this.delay = const Duration(milliseconds: 700)});

  final Duration delay; // 응답을 기다리는 화면 상태를 볼 수 있게 조금 늦춘다

  static final _quoted = RegExp(r'''['‘"“「『]([^'’"”」』]+)['’"”」』]''');
  static const _particles = '을를이가은는의에도와과로';

  @override
  Future<AgentReply> open({
    required Poem poem,
    required String firstWord,
    CancelToken? cancelToken,
  }) async {
    await Future<void>.delayed(delay);
    return _reply(poem, openingFallbackQuestion(firstWord));
  }

  @override
  Future<AgentReply> reply({
    required Poem poem,
    required List<ChatMessage> conversation,
    CancelToken? cancelToken,
  }) async {
    await Future<void>.delayed(delay);
    final userText = conversation.isNotEmpty && conversation.last.isUser
        ? conversation.last.text
        : '';

    // 1) 따옴표로 인용한 구절 → verify_quote. 없으면 첫 낱말로 search_poem_lines 재탐색
    final quote = _quoted.firstMatch(userText)?.group(1)?.trim() ?? '';
    if (quote.isNotEmpty) {
      final check = verifyQuote(poem, quote);
      if (check.isFound) {
        return _reply(
          poem,
          '${check.lineNos.first}행의 그 구절에서 어떤 말이 가장 오래 남았나요?',
          userText: userText,
          quoteChecks: [check],
        );
      }
      final word = _stem(check.quote.split(' ').first);
      final matches = searchPoemLines(poem, word);
      final lineNos = [for (final match in matches) match.lineNo];
      final subject = "'$word'${_particle(word, '이', '가')}";
      final text = switch (lineNos.length) {
        0 => '그 표현은 이 시에서 찾지 못했어요. 어느 행을 읽다가 떠올랐나요?',
        1 => '그 표현은 이 시에 없어요. $subject 나오는 건 ${lineNos.first}행인데, 그 행이었을까요?',
        2 => '그 표현은 이 시에 없어요. $subject 나오는 건 ${lineNos.first}행과 ${lineNos.last}행인데, '
            '둘 중 어느 쪽이었을까요?',
        _ => '그 표현은 이 시에 없어요. $subject 나오는 건 ${lineNos.map((lineNo) => '$lineNo행').join(', ')}인데, '
            '어느 행이었을까요?',
      };
      return _reply(poem, text,
          userText: userText, quoteChecks: [check], searches: [matches]);
    }

    // 2) "N행"으로 짚었으면 그 행을 verify_quote로 확인한다
    final userLineNos = lineNosMentioned(userText, poem);
    if (userLineNos.isNotEmpty) {
      final lineNo = userLineNos.first;
      return _reply(
        poem,
        '$lineNo행의 어떤 말이 그렇게 느끼게 했나요?',
        userText: userText,
        quoteChecks: [verifyQuote(poem, poem.lineAt(lineNo))],
      );
    }

    // 3) 그 밖에는 준비된 관찰 질문을 차례로
    return _reply(poem, nextFallbackQuestion(poem.poemId, conversation),
        userText: userText);
  }

  @override
  Future<AgentReply> hint({
    required Poem poem,
    required List<ChatMessage> conversation,
    CancelToken? cancelToken,
  }) async {
    await Future<void>.delayed(delay);
    return _reply(poem, nextFallbackQuestion(poem.poemId, conversation));
  }

  AgentReply _reply(
    Poem poem,
    String text, {
    String userText = '',
    List<QuoteCheck> quoteChecks = const [],
    List<List<LineMatch>> searches = const [],
  }) {
    final marks = resolveLineMarks(
      poem: poem,
      userText: userText,
      quoteChecks: quoteChecks,
      searches: searches,
      replyText: text,
    );
    return AgentReply(
      text: text,
      evidenceLines: marks.evidenceLines,
      pointingLine: marks.pointingLine,
    );
  }

  /// 낱말 끝의 조사 하나를 뗀다 (별을 → 별)
  String _stem(String word) =>
      word.length > 1 && _particles.contains(word[word.length - 1])
          ? word.substring(0, word.length - 1)
          : word;

  /// 받침이 있으면 [withFinal], 없으면 [withoutFinal] (별이 · 바다가)
  String _particle(String word, String withFinal, String withoutFinal) {
    if (word.isEmpty) return withoutFinal;
    final code = word.codeUnitAt(word.length - 1);
    final hasFinal = code >= 0xAC00 && code <= 0xD7A3 && (code - 0xAC00) % 28 != 0;
    return hasFinal ? withFinal : withoutFinal;
  }
}
