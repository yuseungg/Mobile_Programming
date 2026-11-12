// 주인: D — 저장이 만들어 내는 것들의 규칙 (기획서 6장 「프로필·보상」)
//
// 결정: 뱃지 지급과 공개 대화 생성은 C의 ReadingRepository.save() 안에서
// 한 트랜잭션으로 일어난다. D는 규칙과 문서 내용만 만들고 **호출하지 않는다.**
// 분업표 「B → D: 저장 완료」 항목의 "누가 호출하는지"가 이렇게 정해졌다.
//
// 두 함수 모두 순수하다. 특히 시계를 읽지 않는다 — 기획서 7장이 날짜를 기기
// 시간이 아니라 서버 시간 기준으로 세라고 하므로, createdAt은 C가 넣어 준다.

import '../data/models/public_conversation.dart';
import '../data/models/reading.dart';
import '../data/repositories/public_conversation_repository.dart';

/// 이 저장으로 새로 받는 뱃지 id. 받을 것이 없으면 null.
///
/// 기획서: 「그 시의 해석을 최종 저장하면 획득. 시마다 한 번」.
/// 뱃지 id는 poemId와 같다 (UserProfile.badgeIds).
/// 이미 가진 시면 null을 돌려주므로, 저장을 여러 번 해도 뱃지는 늘지 않는다.
String? badgeToAward({
  required Reading reading,
  required List<String> ownedBadgeIds,
}) {
  if (!reading.isSaved) return null;
  if (reading.poemId.isEmpty) return null;
  if (ownedBadgeIds.contains(reading.poemId)) return null;
  return reading.poemId;
}

/// 이 저장으로 만들 공개 대화 문서. 만들 것이 없으면 null.
///
/// 공개는 기본 꺼짐이고(Reading.isPublic), 해석이 비어 있으면 공개하지 않는다.
/// 공감 수는 0에서 시작한다. 정렬·순위에 쓰지 않는다 (PublicConversation 주석).
///
/// 문서 id는 [publicConversationIdOf]로 사용자 · 시마다 하나로 고정된다.
/// 그래서 "이미 공개했나"가 아니라 **"그 id의 문서가 이미 있나"**([conversationExists])로
/// 판정한다 — 둘은 갈라진다. 해석이 빈 채로 공개 저장하면 공개이지만 대화는 없고,
/// "이미 공개했으니 안 만든다"로 판정하면 그 시는 영구히 공개 대화를 갖지 못한다
/// (PR #12에서 C의 저장소에서 실제로 났던 구멍이고, 규칙을 드린 쪽이 여기다).
///
/// [conversationExists]는 C가 트랜잭션 안에서 읽은 값이다. 생략할 수 없게 두어
/// 빠뜨림을 컴파일 타임에 잡는다. [createdAt]은 서버 시간이어야 한다.
PublicConversation? publicConversationToCreate({
  required String userId,
  required Reading reading,
  required String summary,
  required DateTime createdAt,
  required bool conversationExists,
}) {
  if (!reading.isSaved) return null;
  if (!reading.isPublic) return null;
  if (reading.interpretation.trim().isEmpty) return null;
  if (conversationExists) return null;

  return PublicConversation(
    conversationId: publicConversationIdOf(userId, reading.poemId),
    userId: userId,
    poemId: reading.poemId,
    firstWord: reading.firstWord,
    summary: summary,
    interpretation: reading.interpretation,
    empathyCount: 0,
    evidenceLines: List<int>.unmodifiable(reading.evidenceLines),
    createdAt: createdAt,
  );
}
