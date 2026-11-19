// 주인: A — 미리 준비한 관찰 질문 (기획서 7장: 시별 4개)
// 모델 호출이 실패하거나 출력 필터를 끝내 통과하지 못하면 이 질문으로 대신한다.
// 시 표면(낱말 · 반복 · 행의 위치)에서 답을 찾을 수 있는 질문만 둔다. 해석을 주지 않는다.
// 질문마다 짝이 되는 힌트를 하나 둔다 — 힌트는 그 질문에 다가가는 더 작은 관찰 질문이다.
// ⚠ 초안 — 팀이 읽고 고친다. 시를 추가하면 여기에도 4개를 넣는다.
import '../../data/models/chat_message.dart';

/// 관찰 질문 하나와, 그 질문에서 막혔을 때 보여 줄 힌트
typedef PreparedQuestion = ({String question, String hint});

const preparedQuestions = <String, List<PreparedQuestion>>{
  'seosi': [
    (
      question: '이 시에서 바람은 몇 번 나오고, 그때마다 어떤 말과 함께 나오나요?',
      hint: "'바람'이 처음 나오는 행은 몇 행인가요?",
    ),
    (
      question: '별이 나오는 두 행은 각각 어떤 말과 함께 놓여 있나요?',
      hint: "5행에서 '별' 바로 뒤에 이어지는 말은 무엇인가요?",
    ),
    (
      question: "말끝이 '-야지'나 '-겠다'로 끝나는 행은 어느 행인가요?",
      hint: "각 행의 마지막 낱말만 차례로 읽으면, '-야지'로 끝나는 낱말은 어느 것인가요?",
    ),
    (
      question: '마지막 행만 따로 떨어져 있는데, 앞의 행들과 무엇이 달라 보이나요?',
      hint: '마지막 행에 나오는 낱말 가운데 앞의 행들에도 나왔던 낱말은 무엇인가요?',
    ),
  ],
  'jindallae': [
    (
      question: '1연과 4연을 나란히 놓으면, 같은 말과 달라진 말은 무엇인가요?',
      hint: '1연의 셋째 행과 4연의 셋째 행만 나란히 읽으면 무엇이 다른가요?',
    ),
    (
      question: "말끝이 '-우리다'로 끝나는 행은 모두 몇 개인가요?",
      hint: '각 연의 마지막 행에서 끝의 세 글자만 모으면 무엇이 보이나요?',
    ),
    (
      question: '꽃이 나오는 두 행에서 꽃은 각각 어디에 놓여 있나요?',
      hint: "'꽃'이라는 글자가 들어간 행을 모두 찾으면 몇 행과 몇 행인가요?",
    ),
    (
      question: '떠나는 사람의 걸음과 이어진 말은 어느 행들에 나오나요?',
      hint: "'가실'이나 '가시는'처럼 '가-'로 시작하는 말이 있는 행은 어디인가요?",
    ),
  ],
  'bomgoyangi': [
    (
      question: '네 연에 나오는 고양이의 몸은 각각 어디인가요?',
      hint: "각 연 첫 행의 '고양이의 ○○에'에서 ○○ 자리에는 무엇이 오나요?",
    ),
    (
      question: "'봄'이라는 말 바로 앞에 붙은 말들을 모으면 무엇이 있나요?",
      hint: "2행에서 '봄' 바로 앞에 붙은 말은 무엇인가요?",
    ),
    (
      question: "말끝이 '-도다'로 끝나는 행과 '-아라'로 끝나는 행은 각각 어디인가요?",
      hint: '각 연 둘째 행의 마지막 낱말만 차례로 읽으면 어떻게 들리나요?',
    ),
    (
      question: "'~와 같이'처럼 무엇에 견주는 말이 나오는 행은 어디인가요?",
      hint: "'같이'라는 말이 들어간 행을 찾으면 몇 행인가요?",
    ),
  ],
};

/// 질문을 따로 준비하지 않은 시에 쓰는 질문
const generalPreparedQuestions = <PreparedQuestion>[
  (
    question: '처음 읽을 때 가장 오래 눈이 머문 행은 어디였나요?',
    hint: '처음부터 다시 천천히 읽을 때, 읽는 속도가 느려지는 행은 몇 행인가요?',
  ),
  (
    question: '이 시에서 두 번 이상 나오는 낱말은 무엇인가요?',
    hint: '첫 행에 나오는 낱말 하나를 골라 보면, 그 낱말이 뒤에서 또 나오나요?',
  ),
  (
    question: '첫 행과 마지막 행을 나란히 놓으면 무엇이 달라 보이나요?',
    hint: '첫 행과 마지막 행에 함께 나오는 낱말이 있나요?',
  ),
  (
    question: '소리나 빛처럼 감각이 느껴지는 말은 어느 행에 있나요?',
    hint: '색깔이나 소리를 가리키는 낱말이 나오는 행이 있나요?',
  ),
];

/// 직전 질문이 준비된 질문이 아닐 때(모델이 쓴 질문 · 첫 질문)의 힌트
const followUpHint = '방금 질문에 나온 낱말 하나를 골라 보면, 시에서 그 낱말은 몇 행에 있나요?';

/// 시별 준비된 질문 — 질문 글만
final fallbackQuestions = <String, List<String>>{
  for (final entry in preparedQuestions.entries)
    entry.key: [for (final prepared in entry.value) prepared.question],
};

/// 질문을 따로 준비하지 않은 시에 쓰는 질문 — 질문 글만
final generalFallbackQuestions = [
  for (final prepared in generalPreparedQuestions) prepared.question,
];

/// 대화에 아직 나오지 않은 관찰 질문 하나. 다 썼으면 처음부터 돌아간다.
String nextFallbackQuestion(String poemId, List<ChatMessage> conversation) {
  final questions = fallbackQuestions[poemId] ?? generalFallbackQuestions;
  final asked = {
    for (final message in conversation)
      if (!message.isUser) message.text,
  };
  return questions.firstWhere(
    (question) => !asked.contains(question),
    orElse: () => questions[conversation.length % questions.length],
  );
}

/// AI가 마지막으로 한 질문. 아직 없으면 ''
String lastAgentQuestion(List<ChatMessage> conversation) {
  for (final message in conversation.reversed) {
    if (!message.isUser) return message.text;
  }
  return '';
}

/// 힌트를 모델에게서 받지 못했을 때 — 직전 질문의 짝 힌트.
/// 직전 질문이 준비된 질문이 아니면 [followUpHint], 대화가 비었으면 다음 관찰 질문.
String fallbackHint(String poemId, List<ChatMessage> conversation) {
  final lastQuestion = lastAgentQuestion(conversation);
  if (lastQuestion.isEmpty) return nextFallbackQuestion(poemId, conversation);
  for (final prepared in [
    ...?preparedQuestions[poemId],
    ...generalPreparedQuestions,
  ]) {
    if (prepared.question == lastQuestion) return prepared.hint;
  }
  return followUpHint;
}

/// 첫 질문을 모델에게서 받지 못했을 때 — 첫 낱말에서 출발한다
String openingFallbackQuestion(String firstWord) => firstWord.isEmpty
    ? generalFallbackQuestions.first
    : "'$firstWord'라는 낱말이 남았군요. 어느 행을 읽을 때 그 낱말이 떠올랐나요?";
