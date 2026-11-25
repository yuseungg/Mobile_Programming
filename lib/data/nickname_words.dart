// 주인: C — 무작위 닉네임 (기획서 7장 「무작위 닉네임」)
//
// 형식: 형용사 + 시에 나오는 명사. 예: 조용한 별, 붉은 꽃잎, 나른한 고양이
// 영어로 가입하면 영어 단어로 짓는다. 예: Quiet Star, Drowsy Cat (#55 KR / EN 전환)
// 단어 목록은 기획서 9장 4번(미정)이 정해지면 여기만 고친다.
// 평가하는 말(뛰어난 · 올바른 · best · correct …)은 넣지 않는다.

import 'dart:math';

const nicknameAdjectives = <String>[
  '조용한',
  '푸른',
  '고운',
  '먼',
  '흰',
  '깊은',
  '나른한',
  '붉은',
  '맑은',
  '따스한',
  '작은',
  '느린',
];

/// 수록 작품(서시 · 진달래꽃 · 봄은 고양이로다)에 나오는 명사.
const nicknameNouns = <String>[
  '별',
  '바람',
  '잎새',
  '하늘',
  '밤',
  '길',
  '꽃',
  '진달래',
  '꽃가루',
  '고양이',
  '봄',
  '수염',
];

/// 영어 형용사 — 한국어 목록과 같은 결의 말
const nicknameAdjectivesEn = <String>[
  'Quiet',
  'Blue',
  'Gentle',
  'Distant',
  'White',
  'Deep',
  'Drowsy',
  'Crimson',
  'Clear',
  'Warm',
  'Little',
  'Slow',
];

/// 영어 명사 — 수록 작품 네 편에 나오는 것 (Wood · Road는 The Road Not Taken)
const nicknameNounsEn = <String>[
  'Star',
  'Wind',
  'Leaf',
  'Sky',
  'Night',
  'Road',
  'Flower',
  'Azalea',
  'Pollen',
  'Cat',
  'Spring',
  'Wood',
];

/// 형용사 하나와 명사 하나를 무작위로 골라 붙인다.
/// [english]면 영어 단어로 짓는다 (화면 언어가 EN일 때).
/// [except]를 주면 그것과 다른 조합이 나올 때까지 다시 고른다 (새로고침용).
String drawNickname({Random? random, String? except, bool english = false}) {
  final r = random ?? Random();
  final adjectives = english ? nicknameAdjectivesEn : nicknameAdjectives;
  final nouns = english ? nicknameNounsEn : nicknameNouns;
  String pick() =>
      '${adjectives[r.nextInt(adjectives.length)]} '
      '${nouns[r.nextInt(nouns.length)]}';

  var nickname = pick();
  while (nickname == except) {
    nickname = pick();
  }
  return nickname;
}
