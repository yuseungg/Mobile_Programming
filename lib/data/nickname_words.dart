// 주인: C — 무작위 닉네임 (기획서 7장 「무작위 닉네임」)
//
// 형식: 형용사 + 시에 나오는 명사. 예: 조용한 별, 붉은 꽃잎, 나른한 고양이
// 단어 목록은 기획서 9장 4번(미정)이 정해지면 여기만 고친다.
// 평가하는 말(뛰어난 · 올바른 …)은 넣지 않는다.

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

/// 형용사 하나와 명사 하나를 무작위로 골라 붙인다.
/// [except]를 주면 그것과 다른 조합이 나올 때까지 다시 고른다 (새로고침용).
String drawNickname({Random? random, String? except}) {
  final r = random ?? Random();
  String pick() =>
      '${nicknameAdjectives[r.nextInt(nicknameAdjectives.length)]} '
      '${nicknameNouns[r.nextInt(nicknameNouns.length)]}';

  var nickname = pick();
  while (nickname == except) {
    nickname = pick();
  }
  return nickname;
}
