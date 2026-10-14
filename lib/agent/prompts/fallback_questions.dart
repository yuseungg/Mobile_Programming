// 주인: A — 미리 준비한 관찰 질문 (기획서 7장: 시별 4개)
// 모델 호출이 실패하거나 출력 필터를 끝내 통과하지 못하면 이 질문으로 대신한다.
// 시 표면(낱말 · 반복 · 행의 위치)에서 답을 찾을 수 있는 질문만 둔다. 해석을 주지 않는다.
// ⚠ 초안 — 팀이 읽고 고친다. 시를 추가하면 여기에도 4개를 넣는다.
import '../../data/models/chat_message.dart';

const fallbackQuestions = <String, List<String>>{
  'seosi': [
    '이 시에서 바람은 몇 번 나오고, 그때마다 어떤 말과 함께 나오나요?',
    '별이 나오는 두 행은 각각 어떤 말과 함께 놓여 있나요?',
    "말끝이 '-야지'나 '-겠다'로 끝나는 행은 어느 행인가요?",
    '마지막 행만 따로 떨어져 있는데, 앞의 행들과 무엇이 달라 보이나요?',
  ],
  'jindallae': [
    '1연과 4연을 나란히 놓으면, 같은 말과 달라진 말은 무엇인가요?',
    "말끝이 '-우리다'로 끝나는 행은 모두 몇 개인가요?",
    '꽃이 나오는 두 행에서 꽃은 각각 어디에 놓여 있나요?',
    '떠나는 사람의 걸음과 이어진 말은 어느 행들에 나오나요?',
  ],
  'bomgoyangi': [
    '네 연에 나오는 고양이의 몸은 각각 어디인가요?',
    "'봄'이라는 말 바로 앞에 붙은 말들을 모으면 무엇이 있나요?",
    "말끝이 '-도다'로 끝나는 행과 '-아라'로 끝나는 행은 각각 어디인가요?",
    "'~와 같이'처럼 무엇에 견주는 말이 나오는 행은 어디인가요?",
  ],
};

/// 질문을 따로 준비하지 않은 시에 쓰는 질문
const generalFallbackQuestions = [
  '처음 읽을 때 가장 오래 눈이 머문 행은 어디였나요?',
  '이 시에서 두 번 이상 나오는 낱말은 무엇인가요?',
  '첫 행과 마지막 행을 나란히 놓으면 무엇이 달라 보이나요?',
  '소리나 빛처럼 감각이 느껴지는 말은 어느 행에 있나요?',
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

/// 첫 질문을 모델에게서 받지 못했을 때 — 첫 낱말에서 출발한다
String openingFallbackQuestion(String firstWord) => firstWord.isEmpty
    ? generalFallbackQuestions.first
    : "'$firstWord'라는 낱말이 남았군요. 어느 행을 읽을 때 그 낱말이 떠올랐나요?";
