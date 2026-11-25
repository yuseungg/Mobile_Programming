// 주인: A — 미리 준비한 관찰 질문 (기획서 7장: 시별 4개)
// 모델 호출이 실패하거나 출력 필터를 끝내 통과하지 못하면 이 질문으로 대신한다.
// 시 표면(낱말 · 반복 · 행의 위치)에서 답을 찾을 수 있는 질문만 둔다. 해석을 주지 않는다.
// 질문마다 짝이 되는 힌트를 하나 둔다 — 힌트는 그 질문에 다가가는 더 작은 관찰 질문이다.
// ⚠ 초안 — 팀이 읽고 고친다. 시를 추가하면 여기에도 4개를 넣는다.
// 영어(화면 오른쪽 위 EN)일 때는 아래 영어 질문을 쓴다. 시의 낱말은 원문 그대로 따옴표에 둔다.
import '../../app/language.dart';
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
      hint: "'같이'라는 말이 들어간 행을 모두 찾으면 어느 행들인가요?",
    ),
  ],
};

/// 질문을 따로 준비하지 않은 시에 쓰는 질문
const generalPreparedQuestions = <PreparedQuestion>[
  (
    question: '처음 읽을 때 가장 오래 눈이 머문 행은 어디였나요?',
    hint: '다시 읽으며 낯설거나 처음 보는 낱말을 찾으면, 그 낱말은 몇 행에 있나요?',
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

/// 직전 질문이 준비된 질문이 아닐 때(모델이 쓴 질문 · 첫 질문)의 힌트.
/// 직전 질문이 낱말을 물었든 행을 물었든 통하도록, 시를 한 행씩 짚어 보게 한다.
const followUpHint =
    '한 행씩 짚어 내려가며 방금 질문과 닿아 있는 낱말이 보이는 곳에서 멈추면, 그 행은 몇 행인가요?';

/// 시별 준비된 질문 — 질문 글만
final fallbackQuestions = <String, List<String>>{
  for (final entry in preparedQuestions.entries)
    entry.key: [for (final prepared in entry.value) prepared.question],
};

/// 질문을 따로 준비하지 않은 시에 쓰는 질문 — 질문 글만
final generalFallbackQuestions = [
  for (final prepared in generalPreparedQuestions) prepared.question,
];

/// 영어(화면 EN)용. 한국어와 같은 순서 · 같은 짝이다 — 언어를 바꿔도 같은 자리의 힌트를 찾는다.
const englishPreparedQuestions = <String, List<PreparedQuestion>>{
  'seosi': [
    (
      question: "How many times does '바람' (wind) appear in this poem, and what words come with it each time?",
      hint: "In which line does '바람' (wind) appear for the first time?",
    ),
    (
      question: "In the two lines where '별' (star) appears, what words sit next to it?",
      hint: "In line 5, what word comes right after '별' (star)?",
    ),
    (
      question: "Which lines end with '-야지' or '-겠다'?",
      hint: "If you read only the last word of each line in order, which one ends with '-야지'?",
    ),
    (
      question: 'The last line stands apart on its own. What looks different about it from the lines before?',
      hint: 'Which words in the last line also appeared in the lines before it?',
    ),
  ],
  'jindallae': [
    (
      question: 'If you set stanza 1 beside stanza 4, which words stay the same and which change?',
      hint: 'If you read only the third line of stanza 1 beside the third line of stanza 4, what is different?',
    ),
    (
      question: "How many lines end with '-우리다'?",
      hint: 'If you gather just the last three syllables of the last line of each stanza, what do you see?',
    ),
    (
      question: "In the two lines where '꽃' (flower) appears, where is the flower placed each time?",
      hint: "If you find every line with the letter '꽃' (flower), which lines are they?",
    ),
    (
      question: 'In which lines do words about the steps of the one who leaves appear?',
      hint: "Which lines have a word starting with '가-', like '가실' or '가시는'?",
    ),
  ],
  'bomgoyangi': [
    (
      question: "Which part of the cat's body appears in each of the four stanzas?",
      hint: "In '고양이의 ○○에' in the first line of each stanza, what goes in the place of ○○?",
    ),
    (
      question: "If you gather the words placed right before '봄' (spring), what are they?",
      hint: "In line 2, what word is placed right before '봄' (spring)?",
    ),
    (
      question: "Which lines end with '-도다' and which with '-아라'?",
      hint: 'If you read only the last word of the second line of each stanza in order, how does it sound?',
    ),
    (
      question: "Which lines compare something to something else, with a word like '~와 같이' (like)?",
      hint: "If you find every line with the word '같이' (like), which lines are they?",
    ),
  ],
};

/// 질문을 따로 준비하지 않은 시에 쓰는 질문 (영어)
const generalEnglishPreparedQuestions = <PreparedQuestion>[
  (
    question: 'Which line held your eyes the longest on your first reading?',
    hint: 'Reading it again, if you find a word that feels strange or new, which line is it in?',
  ),
  (
    question: 'Which words appear more than once in this poem?',
    hint: 'Pick one word from the first line. Does it appear again later in the poem?',
  ),
  (
    question: 'If you set the first line beside the last line, what looks different?',
    hint: 'Is there a word that appears in both the first line and the last line?',
  ),
  (
    question: 'In which lines do you find words you can hear or see, like a sound or a light?',
    hint: 'Is there a line with a word for a color or a sound?',
  ),
];

/// [followUpHint]의 영어
const englishFollowUpHint =
    'Go down the poem one line at a time and stop where you see a word connected to that last question. '
    'Which line is it?';

/// 시별 준비된 질문 (영어) — 질문 글만
final englishFallbackQuestions = <String, List<String>>{
  for (final entry in englishPreparedQuestions.entries)
    entry.key: [for (final prepared in entry.value) prepared.question],
};

/// 질문을 따로 준비하지 않은 시에 쓰는 질문 (영어) — 질문 글만
final generalEnglishFallbackQuestions = [
  for (final prepared in generalEnglishPreparedQuestions) prepared.question,
];

/// 대화에 아직 나오지 않은 관찰 질문 하나. 다 썼으면 처음부터 돌아간다.
String nextFallbackQuestion(String poemId, List<ChatMessage> conversation) {
  final questions = isEnglish
      ? englishFallbackQuestions[poemId] ?? generalEnglishFallbackQuestions
      : fallbackQuestions[poemId] ?? generalFallbackQuestions;
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
/// 힌트는 지금 언어(KR / EN)로 준다. 대화 중에 언어를 바꿨으면 직전 질문은 다른 언어일 수 있어서,
/// 두 언어 목록에서 자리를 찾고 그 자리의 힌트를 지금 언어로 꺼낸다.
String fallbackHint(String poemId, List<ChatMessage> conversation) {
  final lastQuestion = lastAgentQuestion(conversation);
  if (lastQuestion.isEmpty) return nextFallbackQuestion(poemId, conversation);
  final korean = [...?preparedQuestions[poemId], ...generalPreparedQuestions];
  final english = [
    ...?englishPreparedQuestions[poemId],
    ...generalEnglishPreparedQuestions,
  ];
  for (var index = 0; index < korean.length && index < english.length; index++) {
    if (korean[index].question == lastQuestion ||
        english[index].question == lastQuestion) {
      return (isEnglish ? english : korean)[index].hint;
    }
  }
  return isEnglish ? englishFollowUpHint : followUpHint;
}

/// 첫 질문을 모델에게서 받지 못했을 때 — 첫 낱말에서 출발한다
String openingFallbackQuestion(String firstWord) => isEnglish
    ? (firstWord.isEmpty
        ? generalEnglishFallbackQuestions.first
        : 'You kept the word "$firstWord". Which line were you reading when it came to mind?')
    : (firstWord.isEmpty
        ? generalFallbackQuestions.first
        : "'$firstWord'라는 낱말이 남았군요. 어느 행을 읽을 때 그 낱말이 떠올랐나요?");
