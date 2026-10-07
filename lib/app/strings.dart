// 주인: 전원 — 각자 자기 화면 문구만 추가하고, 남의 줄은 고치지 않는다.
// 화면에 나오는 한국어 문구는 전부 여기에 모은다.
// 기획서 1장 「쓰지 않는 말」의 세 낱말이 이 파일에 들어가면 안 된다. (확인: grep으로 이 파일만 보면 된다)
// 이름 규칙: 화면_무엇 (docs/여백-네이밍규칙.md 7장)

class AppStrings {
  AppStrings._();

  // ── 공통 ──────────────────────────────────────
  static const appName = '여백';
  static const appSubtitle = '시 읽기 보조바퀴';
  static String charCount(int count, int max) => '$count / $max';
  static String lineLabel(int lineNo) => '$lineNo행';
  static String stopCount(int count) => '$count명';

  // ── 하단 탭바 ─────────────────────────────────
  static const tabPoems = '시';
  static const tabCommunity = '모두의 대화';
  static const tabSettings = '설정';

  // ── S01 로그인 ────────────────────────────────
  static const signInEmailLabel = '이메일';
  static const signInEmailHint = 'example@gmail.com';
  static const signInPasswordLabel = '비밀번호';
  static const signInPasswordHint = '비밀번호를 입력하세요';
  static const signInButton = '로그인';
  static const signInGoogleButton = '구글로 시작하기';
  static const signInOr = '또는';
  static const signInNoAccount = '계정이 없다면';
  static const signInGoToSignUp = '가입하기';

  // ── S02 가입 ──────────────────────────────────
  static const signUpTitle = '가입하기';
  static const signUpHeading = '읽은 것을 남기려면';
  static const signUpSubheading = '구글 이메일로 계정을 만듭니다.';
  static const signUpEmailHelper = 'gmail.com 주소만 쓸 수 있어요';
  static const signUpPasswordHint = '6자 이상';
  static const signUpPasswordHelper = '영문 소문자와 숫자만 쓸 수 있어요';
  static const signUpPasswordConfirmLabel = '비밀번호 확인';
  static const signUpPasswordConfirmHint = '한 번 더 입력하세요';
  static const signUpPasswordMatch = '비밀번호가 일치합니다';
  static const signUpPasswordMismatch = '비밀번호가 서로 다릅니다';
  static const signUpNicknameLabel = '닉네임';
  static const signUpNicknameNotice = '닉네임은 앱이 정해 드립니다. 새로고침하면 바뀝니다.';
  static const signUpNicknameRefresh = '다른 닉네임';
  static const signUpButton = '가입하기';
  static const signUpHaveAccount = '이미 계정이 있다면';
  static const signUpGoToSignIn = '로그인';

  // ── S03 홈 ────────────────────────────────────
  static String homeTotalDays(int days) => '지금까지 $days일\n시를 읽었어요';
  static const homeProfileTooltip = '내 프로필';
  static const homeTodayPoem = '오늘의 시';
  static const homeStartReading = '혼자 읽기 시작';
  static const homeMyPoems = '내가 읽은 시';
  static const homeOtherPoems = '다른 시';
  static const homeStatusSaved = '해석 저장함';
  static const homeStatusInProgress = '읽는 중';

  // ── S04 읽기 ──────────────────────────────────
  static String readingAppBarTitle(String author, String title) =>
      '$author 「$title」';
  static String readingAuthorYear(String author, int year) => '$author · $year';
  static const readingStopGuide = '마음이 멈춘 줄을 눌러 보세요. 아무것도 안 눌러도 됩니다.';
  static const readingFirstWordLabel = '읽고 떠오른 낱말 하나';
  static const readingFirstWordHint = '낱말 하나만 적어 보세요';
  static const readingStartChat = '이 낱말로 대화 시작';
  static const readingEndWithWord = '낱말만 남기고 끝내기';

  // ── S05 대화 ──────────────────────────────────
  static String chatTitle(String title) => '$title — 읽는 중';
  static const chatHintButton = '힌트 더 주세요';
  static const chatHintTitle = '시에서 찾아볼 것';
  static const chatSummarizeButton = '내 해석 정리하기';
  static const chatInputHint = '생각을 적어 보세요';
  static const chatSendButton = '보내기';
  static const chatPoemToggleShow = '시 펼치기';
  static const chatPoemToggleHide = '시 접기';

  // ── S06 정리 · 저장 ───────────────────────────
  static const saveTitle = '내 해석';
  static const saveInterpretationLabel = '내 해석';
  static const saveDraftNotice = '대화에서 나온 말을 모았습니다. 고쳐서 저장하세요 — 저장하는 문장은 당신 것이어야 합니다.';
  static const saveEvidenceLabel = '내가 근거로 삼은 구절';
  static const savePublicLabel = '대화를 모두의 대화에 공개';
  static const savePublicCaption = 'AI가 대화에서 의미 있는 내용만 뽑아 닉네임과 함께 올립니다';
  static const saveLockNotice = '저장한 뒤에야 전문가 해석과 다른 사람의 대화가 열립니다.';
  static const saveButton = '저장하기';

  // ── S07 대조 ──────────────────────────────────
  static const comparisonTitle = '대조';
  static const comparisonMine = '내 해석';
  static const comparisonPoemToggle = '시 다시 보기';
  static const comparisonRelationSameLines = '같은 곳을 봤어요';
  static const comparisonRelationPartialOverlap = '같은 줄에서 출발했어요';
  static String comparisonRelationDifferentLines(int lineNo) =>
      '이 해석은 $lineNo행을 중심으로 읽었어요';
  static const comparisonNoExperts = '이 시의 전문가 해석은 준비 중이에요.';
  static const comparisonCreationBackground = '창작 배경 보기';
  static const comparisonCreationBackgroundTitle = '창작 배경';
  static const comparisonGoCommunity = '다른 사람의 대화 보기';

  // ── S08 대화 목록 ─────────────────────────────
  static const communityTitle = '모두의 대화';
  static const communityGuide = '같은 시를 읽은 사람들이 AI와 나눈 대화예요.';
  static const communityEmpty = '아직 공개된 대화가 없어요.';
  static String communityFirstWord(String word) => '첫 낱말 · $word';

  // ── S09 대화 보기 ─────────────────────────────
  static const communityDetailFirstWord = '첫 낱말';
  static const communityDetailSummary = '대화 요약';
  static const communityDetailInterpretation = '최종 해석';
  static const communityDetailEmpathy = '공감';
  static String communityDetailEmpathyCount(int count) => '공감 $count';

  // ── S10 설정 보기 ─────────────────────────────
  static const settingsTitle = '설정';
  static const settingsModelSection = 'AI 모델';
  static const settingsQuestionModel = '질문 · 힌트';
  static const settingsComparisonModel = '비교 · 요약';
  static const settingsModelCaption = '질문에는 신중한 모델, 비교와 요약에는 빠른 모델을 써요.';
  static const settingsToneSection = 'AI 말투';
  static const settingsUsageSection = '이번 달 사용량';
  static String settingsUsage(int questionCount, int comparisonCount) =>
      '질문 $questionCount회 · 비교 $comparisonCount회';
  static const settingsEditButton = '설정 바꾸기';

  // ── S11 설정 바꾸기 ───────────────────────────
  static const settingsEditTitle = '설정 바꾸기';
  static const settingsEditQuestionModel = '질문을 만들 때 쓸 모델';
  static const settingsEditComparisonModel = '비교할 때 쓸 모델';
  static const settingsEditTone = 'AI 말투';
  static const settingsEditDeleteHistory = '대화 기록 지우기';
  static const settingsEditDeleteAction = '지우기';
  static const settingsEditSave = '저장';

  // 말투 (S10 · S11 공용)
  static const tonePlain = '담백하게';
  static const toneGentle = '부드럽게';

  // ── S12 프로필 ────────────────────────────────
  static const profileTitle = '프로필';
  static const profileTotalDaysLabel = '시를 읽은 날';
  static String profileTotalDays(int days) => '$days일';
  static const profileBadges = '받은 뱃지';
  static const profileNoBadges = '아직 받은 뱃지가 없어요.';
}
