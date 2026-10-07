// 1단계(화면) 확인용 가짜 데이터. 2단계에서 진짜 저장소로 바꾼다.
// 이름은 docs/여백-네이밍규칙.md 2장 용어 사전을 그대로 쓴다.
//
// ⚠ 공개 대화·프로필은 화면을 눌러보기 위한 임시 값이다.
//   시연용 커뮤니티 데이터는 팀원이 직접 대화해서 채운다 (기획서 9장 7번).
// ⚠ 모델 이름은 교수님 키로 열린 모델을 확인하기 전 임시 값이다 (기획서 9장 1번).
//
// 출처: 시 본문·내 읽기·설정은 C, 멈춤 집계는 B(part-b), 전문가 해석·공개 대화·다른 사람 프로필은
//       D(part-d)의 가짜 데이터를 이름만 맞춰 옮겼다 (docs/여백-이름대조표.md).

import '../models/chat_message.dart';
import '../models/expert_interpretation.dart';
import '../models/poem.dart';
import '../models/public_conversation.dart';
import '../models/reading.dart';
import '../models/settings.dart';
import '../models/user_profile.dart';

class FakeData {
  FakeData._();

  static const myUserId = 'me';

  // ── 시 ────────────────────────────────────────
  // 연 구분은 빈 문자열("")이고 행 번호를 하나 차지한다. 서시의 마지막 행은 10행.
  static const poems = <Poem>[
    Poem(
      poemId: 'seosi',
      title: '서시',
      author: '윤동주',
      year: 1941,
      lines: [
        '죽는 날까지 하늘을 우러러',
        '한 점 부끄럼이 없기를,',
        '잎새에 이는 바람에도',
        '나는 괴로워했다.',
        '별을 노래하는 마음으로',
        '모든 죽어가는 것을 사랑해야지',
        '그리고 나한테 주어진 길을',
        '걸어가야겠다.',
        '',
        '오늘 밤에도 별이 바람에 스치운다.',
      ],
      creationBackground:
          '1941년 11월 20일에 썼다. 윤동주가 연희전문학교 졸업을 앞두고 엮은 '
          '자필 시고집의 맨 앞에 놓인 시다. 시인은 1945년 2월 후쿠오카 형무소에서 '
          '세상을 떠났고, 이 시는 1948년 유고 시집 『하늘과 바람과 별과 시』에 실렸다.',
    ),
    Poem(
      poemId: 'jindallae',
      title: '진달래꽃',
      author: '김소월',
      year: 1922,
      lines: [
        '나 보기가 역겨워',
        '가실 때에는',
        '말없이 고이 보내 드리우리다',
        '',
        '영변에 약산',
        '진달래꽃',
        '아름 따다 가실 길에 뿌리우리다',
        '',
        '가시는 걸음걸음',
        '놓인 그 꽃을',
        '사뿐히 즈려밟고 가시옵소서',
        '',
        '나 보기가 역겨워',
        '가실 때에는',
        '죽어도 아니 눈물 흘리우리다',
      ],
      creationBackground:
          '1922년 잡지 『개벽』에 처음 실렸다. 1925년 김소월이 생전에 낸 단 하나의 '
          '시집의 표제작이 되었다. 영변의 약산은 평안북도에 있는 산으로, '
          '봄이면 진달래로 이름난 곳이다.',
    ),
    Poem(
      poemId: 'bomgoyangi',
      title: '봄은 고양이로다',
      author: '이장희',
      year: 1924,
      lines: [
        '꽃가루와 같이 부드러운 고양이의 털에',
        '고운 봄의 향기가 어리우도다.',
        '',
        '금방울과 같이 호동그란 고양이의 눈에',
        '미친 봄의 불길이 흐르도다.',
        '',
        '고요히 다물은 고양이의 입술에',
        '포근한 봄 졸음이 떠돌아라.',
        '',
        '날카롭게 쭉 뻗은 고양이의 수염에',
        '푸른 봄의 생기가 뛰놀아라.',
      ],
      creationBackground:
          '1924년 동인지 『금성』에 발표했다. 이장희는 생전에 시집을 내지 못했고, '
          '1929년 세상을 떠났다. 그의 시는 사후에 엮인 유고집으로 전한다.',
    ),
  ];

  /// 오늘의 시 (기획서 9장 3번 — 선정 방식 미정)
  static const todayPoemId = 'seosi';

  // ── 멈춤 집계: 행 번호 → 멈춘 사람 수 ────────────
  static const stopCounts = <String, Map<int, int>>{
    'seosi': {2: 12, 4: 5, 6: 8, 10: 15}, // B
    'jindallae': {3: 2, 9: 4, 11: 6, 15: 5},
    'bomgoyangi': {1: 3, 5: 4, 8: 2},
  };

  // ── 전문가 해석 (기획서 7장 형식) ─────────────────
  static const expertInterpretations = <String, List<ExpertInterpretation>>{
    'seosi': [
      ExpertInterpretation(
        label: '전문가 해석 A',
        stance: '부끄러움과 다짐으로 읽는 입장',
        claims: [
          Claim(lines: [2], point: '부끄럼 없기를 바라는 건 도달할 수 없는 기준이다'),
          Claim(lines: [6, 7, 8], point: '괴로움을 통과한 뒤에 나온 다짐이다'),
        ],
      ),
      ExpertInterpretation(
        label: '전문가 해석 B',
        stance: '시대 앞의 무력감으로 읽는 입장',
        claims: [
          Claim(lines: [10], point: '다짐 뒤에도 밤은 그대로 온다'),
        ],
      ),
    ],
  };

  // ── 비교 문장 (2단계에서 비교 모델이 쓴다) ──────────
  // 전문가 해석 순서와 같은 순서. 공통점부터 말하고, 내가 놓친 것을 가리키지 않는다 (기획서 4장).
  // 관계(같은 곳을 봤어요 등)는 문장이 아니라 코드가 계산한다 → lib/compare/relation.dart
  static const comparisonTexts = <String, List<String>>{
    'seosi': [
      '두 읽기 모두 6행의 다짐에 머물러요. 내 해석은 그 다짐을 '
          '자기를 견디는 말로 읽었고, 이 해석은 괴로움을 지나온 뒤에 나온 결심으로 읽어요.',
      '두 읽기는 서로 다른 줄에서 출발해요. 내 해석은 6행의 '
          '사랑하겠다는 다짐에, 이 해석은 10행에서 여전히 부는 밤바람에 무게를 둬요.',
    ],
  };

  // ── 내 읽기 ───────────────────────────────────
  static const myReadings = <String, Reading>{
    'seosi': Reading(
      poemId: 'seosi',
      firstWord: '부끄러움',
      markedLines: [6],
      conversation: [
        ChatMessage(
          role: ChatRole.assistant,
          text: "'부끄러움'이라는 낱말이 남았군요. 어느 줄을 읽을 때 그 낱말이 떠올랐나요?",
        ),
        ChatMessage(
          role: ChatRole.user,
          text: "'별을 그리워하며'라는 구절 때문인 것 같아요.",
        ),
        ChatMessage(
          role: ChatRole.assistant,
          text: "그 표현은 이 시에 없어요. '별'이 나오는 건 5행과 10행인데, 둘 중 어느 쪽이었을까요?",
        ),
        ChatMessage(
          role: ChatRole.user,
          text: '아, 5행이요. 그런데 다시 보니 6행이 더 마음에 남아요.',
        ),
        ChatMessage(
          role: ChatRole.assistant,
          text: "6행의 '모든 죽어가는 것'에는 누가 들어 있다고 느꼈나요?",
        ),
        ChatMessage(
          role: ChatRole.user,
          text: '부끄러워하는 나 자신도 들어 있는 것 같아요. 그래서 사랑하겠다는 말이 나를 견디는 말처럼 들렸어요.',
        ),
      ],
      evidenceLines: [6],
      interpretation: '부끄러움을 아는 사람이 끝내 고르는 것은 사랑이다. '
          "'모든 죽어가는 것'에는 부끄러워하는 나 자신도 들어 있어서, "
          '사랑하겠다는 다짐은 남을 향한 말이면서 나를 견디는 말처럼 들린다.',
      isSaved: true,
    ),
    'jindallae': Reading(
      poemId: 'jindallae',
      firstWord: '이별',
      markedLines: [11],
      conversation: [
        ChatMessage(
          role: ChatRole.assistant,
          text: "'이별'이라는 낱말을 남겼네요. 이 시에서 떠나는 사람과 남는 사람은 각각 누구일까요?",
        ),
        ChatMessage(
          role: ChatRole.user,
          text: '떠나는 건 님이고 남는 건 나 같아요.',
        ),
      ],
    ),
  };

  /// 대화 중 "지금 가리키는 중"인 행 (회색 점선). 2단계에서 A의 에이전트가 정한다.
  static const pointingLines = <String, int>{'seosi': 5};

  /// 힌트 — 시 표면에서 찾을 수 있는 관찰 질문. 해석을 주지 않는다.
  static const hints = <String, String>{
    'seosi': '이 시에서 바람은 몇 번 나오고, 각각 어떤 말과 함께 나오나요?',
    'jindallae': '첫 연과 마지막 연에서 같은 말과 달라진 말은 무엇인가요?',
    'bomgoyangi': '연마다 고양이의 어느 부분이 나오나요?',
  };

  // ── 공개 대화 (D) ─────────────────────────────
  static final publicConversations = <PublicConversation>[
    PublicConversation(
      conversationId: 'post_1',
      userId: 'user_star_1',
      poemId: 'seosi',
      firstWord: '부끄러움',
      summary: '화자가 느끼는 부끄러움의 깊이에 대해 대화했습니다. '
          'AI의 질문을 통해 사소한 흔들림(잎새에 이는 바람)조차 스스로에게 엄격했던 '
          '시인의 결벽에 가까운 순수함을 발견했습니다.',
      evidenceLines: const [2, 3, 4],
      interpretation: '완벽할 수 없음을 알면서도 스스로에게 부끄럽지 않으려 고뇌했던 '
          '한 젊은이의 고결한 아픔이 느껴졌다. '
          '그 부끄러움은 나약함이 아니라 가장 정직한 용기다.',
      empathyCount: 14,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    PublicConversation(
      conversationId: 'post_2',
      userId: 'user_wind_2',
      poemId: 'seosi',
      firstWord: '다짐',
      summary: '괴로움 이후에 등장하는 태도의 변화를 추적했습니다. '
          '6행의 "모든 죽어가는 것"이 무엇을 의미하는지 질문을 받으며, '
          '자기 연민을 넘어선 더 넓은 존재들에 대한 사랑과 연대임을 짚어냈습니다.',
      evidenceLines: const [6, 7, 8],
      interpretation: '괴로움을 통과한 자만이 말할 수 있는 진정한 걸음이다. '
          '거창한 영웅적 결단이 아니라 나한테 주어진 길을 묵묵히 걸어가겠다는 단단한 선언이다.',
      empathyCount: 29,
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
    ),
    PublicConversation(
      conversationId: 'post_3',
      userId: 'user_night_3',
      poemId: 'seosi',
      firstWord: '밤',
      summary: '마지막 10행의 고독한 분위기를 중심으로 대화했습니다. '
          '다짐을 마쳤음에도 불구하고 왜 여전히 "밤"이고 "바람"이 스치는지 질문하며 '
          '끝나지 않는 현실의 무게를 성찰했습니다.',
      evidenceLines: const [10],
      interpretation: '다짐했다고 해서 세상이 바로 밝아지는 것은 아니다. '
          '밤은 여전히 춥고 바람은 불지만, 그 속에서도 별을 바라보겠다는 '
          '위태롭고도 애틋한 시선이 남는다.',
      empathyCount: 8,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  // ── 사용자 ────────────────────────────────────
  static final profiles = <String, UserProfile>{
    myUserId: UserProfile(
      userId: myUserId,
      nickname: '조용한 별',
      totalReadingDays: 12,
      lastCountedDate: DateTime(2026, 10, 7),
      badgeIds: const ['seosi'],
    ),
    // 아래는 D의 가짜 데이터. 닉네임은 겹치면 안 되므로 '조용한 별'(내 닉네임)과
    // 겹치던 user_star_1은 D가 쓰던 다른 닉네임 '새벽의 별빛'으로 바꿨다.
    'user_star_1': UserProfile(
      userId: 'user_star_1',
      nickname: '새벽의 별빛',
      totalReadingDays: 12,
      lastCountedDate: DateTime(2026, 10, 6),
      badgeIds: const ['seosi', 'jindallae'],
    ),
    'user_wind_2': UserProfile(
      userId: 'user_wind_2',
      nickname: '푸른 바람',
      totalReadingDays: 24,
      lastCountedDate: DateTime(2026, 10, 7),
      badgeIds: const ['seosi', 'jindallae', 'bomgoyangi'],
    ),
    'user_night_3': UserProfile(
      userId: 'user_night_3',
      nickname: '깊은 밤',
      totalReadingDays: 3,
      lastCountedDate: DateTime(2026, 10, 5),
      badgeIds: const ['seosi'],
    ),
  };

  /// S02 무작위 닉네임 새로고침용 (기획서 9장 4번 — 단어 목록 미정)
  static const nicknameCandidates = <String>[
    '조용한 별',
    '푸른 잎새',
    '고운 봄',
    '먼 바람',
    '흰 꽃가루',
    '깊은 하늘',
  ];

  // ── 설정 ──────────────────────────────────────
  /// S11 모델 선택지 (목업: 3개 중 하나). 이름은 임시 값.
  static const modelOptions = <({String model, String description})>[
    (model: 'google/gemma-3-27b-it:free', description: '가장 신중함 · 느림'),
    (model: 'meta-llama/llama-4-maverick:free', description: '균형 · 보통'),
    (model: 'mistralai/mistral-small-3.2-24b-instruct:free', description: '가장 빠름'),
  ];

  static const settings = Settings(
    questionModel: 'google/gemma-3-27b-it:free',
    comparisonModel: 'mistralai/mistral-small-3.2-24b-instruct:free',
    tone: Tone.plain,
  );

  static const usageQuestionCount = 42;
  static const usageComparisonCount = 18;

  // ── 찾기 ──────────────────────────────────────
  // 1단계에서는 잘못된 id가 들어와도 화면이 열리도록 첫 번째 값으로 대신한다.

  static Poem poemById(String poemId) => poems.firstWhere(
        (poem) => poem.poemId == poemId,
        orElse: () => poems.first,
      );

  static Reading? readingFor(String poemId) => myReadings[poemId];

  static UserProfile profileById(String userId) =>
      profiles[userId] ?? profiles[myUserId]!;

  static PublicConversation conversationById(String conversationId) =>
      publicConversations.firstWhere(
        (conversation) => conversation.conversationId == conversationId,
        orElse: () => publicConversations.first,
      );

  /// 최신순. 공감 수로 정렬하지 않는다 (기획서 9장 2번).
  static List<PublicConversation> conversationsFor(String poemId) =>
      publicConversations
          .where((conversation) => conversation.poemId == poemId)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
}
