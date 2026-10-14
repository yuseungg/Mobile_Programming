// 주인: A — 대화 화면(S05)과 에이전트 사이의 약속
// 화면은 이 인터페이스만 안다. 키가 있으면 OpenRouter로 묻고, 없으면 가짜 에이전트가 답한다.
// 근거 행 형식: 1부터 세는 행 번호 목록 (A → B · D 계약, 코딩분업 3장)
import '../data/models/chat_message.dart';
import '../data/models/poem.dart';
import '../data/models/settings.dart';
import 'cancel_token.dart';
import 'fake_chat_agent.dart';
import 'openrouter_chat_agent.dart';
import 'openrouter_client.dart';

/// 에이전트가 한 번 답한 결과
class AgentReply {
  const AgentReply({
    required this.text,
    this.evidenceLines = const [],
    this.pointingLine,
    this.isFallback = false,
  });

  final String text; // 화면에 보여 줄 AI의 말 — 항상 질문 하나로 끝난다
  final List<int> evidenceLines; // 이번 턴에 확인된 근거 행 — 초록 실선
  final int? pointingLine; // AI가 지금 가리키는 행 — 회색 점선
  final bool isFallback; // 모델 대신 미리 준비한 관찰 질문을 썼는가
}

abstract interface class ChatAgent {
  /// 대화가 비어 있을 때 첫 질문. [firstWord]는 S04에서 남긴 첫 낱말 (없으면 '')
  Future<AgentReply> open({
    required Poem poem,
    required String firstWord,
    CancelToken? cancelToken,
  });

  /// 사용자 말에 대한 다음 질문. [conversation]의 마지막은 방금 보낸 사용자 말이다.
  Future<AgentReply> reply({
    required Poem poem,
    required List<ChatMessage> conversation,
    CancelToken? cancelToken,
  });

  /// 힌트 (기획서 F3) — 시 표면에서 답을 찾을 수 있는 관찰 질문 하나
  Future<AgentReply> hint({
    required Poem poem,
    required List<ChatMessage> conversation,
    CancelToken? cancelToken,
  });
}

/// 개발 중에 모델을 바꿔 끼울 때: .env(또는 --dart-define)에 OPENROUTER_QUESTION_MODEL=모델 id
/// 비어 있으면 설정(S10 · S11)의 질문 모델을 쓴다.
const _questionModelOverride = String.fromEnvironment('OPENROUTER_QUESTION_MODEL');

/// 키가 있고 이 플랫폼에서 보낼 수 있으면 진짜 에이전트, 아니면 가짜 에이전트
ChatAgent createChatAgent({required Settings settings, required bool isSaved}) {
  final client = OpenRouterClient();
  if (!client.isAvailable) return FakeChatAgent();
  return OpenRouterChatAgent(
    client: client,
    model: _questionModelOverride.isEmpty
        ? settings.questionModel
        : _questionModelOverride,
    tone: settings.tone,
    isSaved: isSaved,
  );
}
