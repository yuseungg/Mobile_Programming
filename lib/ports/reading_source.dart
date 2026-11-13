// 주인: D — D 화면이 데이터를 읽는 창구 (S07 · S08 · S09 · S12)
//
// 화면이 FakeData를 직접 부르면 C의 Firestore 저장소가 나왔을 때 화면마다
// 고쳐야 한다. 그래서 읽기에 필요한 것만 여기 모아 두고, 화면은 이 인터페이스
// 하나만 본다. C의 저장소가 나오면 구현체를 하나 더 만들어 끼운다.
//
// **비동기다.** Firestore 읽기와 에셋 읽기가 모두 Future라서, 지금 동기로
// 만들면 2단계에 화면을 다시 뜯게 된다.
//
// 경로 문자열(users/{uid}/readings/...)은 여기에도 화면에도 나오지 않는다.
// 컬렉션 경로는 C의 저장소 안에만 있다.

import '../data/models/expert_interpretation.dart';
import '../data/models/poem.dart';
import '../data/models/public_conversation.dart';
import '../data/models/reading.dart';
import '../data/models/user_profile.dart';

abstract interface class ReadingSource {
  /// 지금 로그인한 사람
  String get myUserId;

  /// 오늘의 시 — S08이 처음 열릴 때 고를 시
  String get todayPoemId;

  /// 수록된 시 전체
  Future<List<Poem>> poems();

  Future<Poem> poemById(String poemId);

  /// 그 시에 대한 내 읽기. 없으면 null (= 아직 읽지 않았다)
  Future<Reading?> readingFor(String poemId);

  /// 내 읽기 전체 — S13이 학습 현황과 인상깊은 문구를 모을 때 쓴다.
  /// 아직 아무 시도 안 읽었으면 빈 목록이다.
  Future<List<Reading>> myReadings();

  Future<UserProfile> profileById(String userId);

  /// 그 시의 공개 대화. 최신순이고 공감 수로 정렬하지 않는다 (기획서 9장)
  Future<List<PublicConversation>> conversationsFor(String poemId);

  Future<PublicConversation> conversationById(String conversationId);

  /// 그 시의 전문가 해석. 아직 없으면 빈 목록 → S07은 「준비 중」을 보여 준다
  Future<List<ExpertInterpretation>> expertsFor(String poemId);

  /// 전문가 해석과 같은 순서의 비교 문장. 아직 없으면 빈 목록
  Future<List<String>> comparisonTextsFor(String poemId);

  /// S07을 열었다고 알린다 — **읽기 창구에서 유일하게 쓰는 쪽이다.**
  ///
  /// 대조를 한 번 보면 그 뒤로 해석을 고칠 수 없다 (기획서 4장). 그 잠금을
  /// 거는 지점이 S07을 여는 순간이고, 화면이 C의 저장소를 직접 알지 않도록
  /// 여기로 받는다. 이미 열었거나 아직 저장 전이면 저장소가 알아서 넘긴다.
  ///
  /// 저장이 실패해도 대조는 보여야 하므로 **예외를 던지지 않는다.**
  Future<void> markComparisonOpened(String poemId);
}
