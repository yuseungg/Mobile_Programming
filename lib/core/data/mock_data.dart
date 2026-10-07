import '../../models/community_post.dart';
import '../../models/expert_reading.dart';
import '../../models/poem.dart';
import '../../models/poem_badge.dart';
import '../../models/user_profile.dart';

/// D 담당 첫날 공용 산출물 — 앱 전역에서 참조 가능한 가짜 데이터 (Mock Data)
class MockData {
  MockData._();

  // ==========================================
  // 1. 뱃지 데이터 (시 완독 시 주어지는 상징 뱃지)
  // ==========================================
  static final PoemBadge badgeStar = PoemBadge(
    id: 'badge_star',
    poemId: 'seosi',
    name: '별',
    poemTitle: '서시',
    iconSymbol: '✦',
    acquiredDate: DateTime(2026, 10, 1),
  );

  static final PoemBadge badgeFlower = PoemBadge(
    id: 'badge_flower',
    poemId: 'jindallae',
    name: '꽃',
    poemTitle: '진달래꽃',
    iconSymbol: '✿',
    acquiredDate: DateTime(2026, 10, 3),
  );

  static final PoemBadge badgeCat = PoemBadge(
    id: 'badge_cat',
    poemId: 'cat_spring',
    name: '고양이',
    poemTitle: '봄은 고양이로다',
    iconSymbol: '🐾',
    acquiredDate: null, // 미획득 예시
  );

  // ==========================================
  // 2. 윤동주 <서시> 본문 및 전문가 해석 (기준 시)
  // ==========================================
  static final Poem seosi = Poem(
    id: 'seosi',
    title: '서시',
    poet: '윤동주',
    year: 1941,
    lines: const [
      '죽는 날까지 하늘을 우러러', // 1행
      '한 점 부끄럼이 없기를,', // 2행
      '잎새에 이는 바람에도', // 3행
      '나는 괴로워했다.', // 4행
      '별을 노래하는 마음으로', // 5행
      '모든 죽어가는 것을 사랑해야지', // 6행
      '그리고 나한테 주어진 길을', // 7행
      '걸어가야겠다.', // 8행
      '', // 9행 (연 구분)
      '오늘 밤에도 별이 바람에 스치운다.', // 10행
    ],
    historicalContext:
        '1941년 11월 20일 연희전문학교 졸업을 앞두고 쓴 시로, '
        '유고 시집 『하늘과 바람과 별과 시』의 서시로 수록되었다. '
        '일제강점기 말기 우리말과 글을 빼앗기던 엄혹한 시대 상황 속에서 지어졌다.',
    expertReadings: const [
      ExpertReading(
        label: '전문가 해석 A',
        stance: '부끄러움과 다짐으로 읽는 입장',
        claims: [
          ExpertClaim(
            lines: [2],
            point: '부끄럼 없기를 바라는 건 도달할 수 없는 기준이다',
          ),
          ExpertClaim(
            lines: [6, 7, 8],
            point: '괴로움을 통과한 뒤에 나온 다짐이다',
          ),
        ],
        fullText:
            '화자는 스스로에게 지극히 엄격한 도덕적 잣대를 들이대며 끊임없이 자성합니다. '
            '그러나 자책에만 머무르지 않고, 자신이 겪은 고뇌를 딛고 일어서 '
            '주어진 길을 끝내 걸어가겠다는 윤리적 결의로 나아갑니다.',
        comparisonSentence:
            '내면의 부끄러움과 괴로움에 주목하며, 이를 극복하고 자신의 길을 걸어가겠다는 굳은 다짐을 함께 읽어냈습니다.',
      ),
      ExpertReading(
        label: '전문가 해석 B',
        stance: '시대 앞의 무력감으로 읽는 입장',
        claims: [
          ExpertClaim(
            lines: [10],
            point: '다짐 뒤에도 밤은 그대로 온다',
          ),
        ],
        fullText:
            '결연한 다짐(8행) 이후에도 마지막 행에서 별은 여전히 바람에 위태롭게 스치웁니다. '
            '시대적 어둠과 개인의 무력감이라는 비극적 현실은 쉽게 해소되지 않으며, '
            '결의 뒤에도 짙은 불안과 한계가 지속됨을 보여줍니다.',
        comparisonSentence:
            '다짐의 숭고함보다는 마지막 행의 어두운 밤과 차가운 바람에 깃든 시대적 한계와 비극성에 집중했습니다.',
      ),
    ],
    badge: badgeStar,
  );

  // ==========================================
  // 3. 커뮤니티 공개 대화 글 3개
  // ==========================================
  static final List<CommunityPost> communityPosts = [
    CommunityPost(
      id: 'post_1',
      authorUid: 'user_star_1',
      authorNickname: '조용한 별',
      poemId: 'seosi',
      poemTitle: '서시',
      firstWord: '부끄러움',
      aiSummary:
          '화자가 느끼는 부끄러움의 깊이에 대해 대화했습니다. '
          'AI의 질문을 통해 사소한 흔들림(잎새에 이는 바람)조차 스스로에게 엄격했던 시인의 결벽에 가까운 순수함을 발견했습니다.',
      groundedLines: const [2, 3, 4],
      finalInterpretation:
          '완벽할 수 없음을 알면서도 스스로에게 부끄럽지 않으려 고뇌했던 한 젊은이의 고결한 아픔이 느껴졌다. '
          '그 부끄러움은 나약함이 아니라 가장 정직한 용기다.',
      empathyCount: 14,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    CommunityPost(
      id: 'post_2',
      authorUid: 'user_wind_2',
      authorNickname: '푸른 바람',
      poemId: 'seosi',
      poemTitle: '서시',
      firstWord: '다짐',
      aiSummary:
          '괴로움 이후에 등장하는 태도의 변화를 추적했습니다. '
          '6행의 "모든 죽어가는 것"이 무엇을 의미하는지 질문을 받으며, '
          '자기 연민을 넘어선 더 넓은 존재들에 대한 사랑과 연대임을 짚어냈습니다.',
      groundedLines: const [6, 7, 8],
      finalInterpretation:
          '괴로움을 통과한 자만이 말할 수 있는 진정한 걸음이다. '
          '거창한 영웅적 결단이 아니라 나한테 주어진 길을 묵묵히 걸어가겠다는 단단한 선언이다.',
      empathyCount: 29,
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
    ),
    CommunityPost(
      id: 'post_3',
      authorUid: 'user_night_3',
      authorNickname: '깊은 밤',
      poemId: 'seosi',
      poemTitle: '서시',
      firstWord: '밤',
      aiSummary:
          '마지막 10행의 고독한 분위기를 중심으로 대화했습니다. '
          '다짐을 마쳤음에도 불구하고 왜 여전히 "밤"이고 "바람"이 스치는지 질문하며 '
          '끝나지 않는 현실의 무게를 성찰했습니다.',
      groundedLines: const [10],
      finalInterpretation:
          '다짐했다고 해서 세상이 바로 밝아지는 것은 아니다. '
          '밤은 여전히 춥고 바람은 불지만, 그 속에서도 별을 바라보겠다는 위태롭고도 애틋한 시선이 남는다.',
      empathyCount: 8,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  // ==========================================
  // 4. 프로필 목업 데이터 (내 프로필 및 타인 프로필)
  // ==========================================
  static final UserProfile myProfile = UserProfile(
    uid: 'current_user_me',
    nickname: '새벽의 별빛',
    streakDays: 5,
    badges: [badgeStar, badgeFlower],
  );

  static final Map<String, UserProfile> otherProfiles = {
    'user_star_1': UserProfile(
      uid: 'user_star_1',
      nickname: '조용한 별',
      streakDays: 12,
      badges: [badgeStar, badgeFlower],
    ),
    'user_wind_2': UserProfile(
      uid: 'user_wind_2',
      nickname: '푸른 바람',
      streakDays: 24,
      badges: [badgeStar, badgeFlower, badgeCat],
    ),
    'user_night_3': UserProfile(
      uid: 'user_night_3',
      nickname: '깊은 밤',
      streakDays: 3,
      badges: [badgeStar],
    ),
  };

  // ==========================================
  // 5. 현재 사용자의 최근 해석 예시 (S07 대조 화면 테스트용)
  // ==========================================
  static const String mySampleInterpretation =
      '자신을 괴롭히던 부끄러움을 딛고, 모든 죽어가는 것들을 품으며 '
      '나에게 주어진 길을 꿋꿋하게 걸어가겠다는 순수하고 단단한 결의가 마음에 와닿았다.';

  static const List<int> mySampleGroundedLines = [2, 6, 8];
}
