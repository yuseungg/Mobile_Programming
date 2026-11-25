// 주인: 전원 — 각자 자기 화면 문구만 추가하고, 남의 줄은 고치지 않는다.
// 화면에 나오는 문구는 전부 여기에 모은다. 한 줄마다 한국어와 영어를 함께 적는다:
//   static String get close => _t('닫기', 'Close');
// 어느 쪽을 보여 줄지는 lib/app/language.dart의 appLanguage가 정한다 (전 화면 오른쪽 위 KR / EN).
// 기획서 1장 「쓰지 않는 말」의 세 낱말이 이 파일에 들어가면 안 된다. (확인: grep으로 이 파일만 보면 된다)
// 영어 문구도 같은 뜻의 낱말(answer · correct · explanation · commentary)을 쓰지 않는다.
// 이름 규칙: 화면_무엇 (docs/여백-네이밍규칙.md 7장)
//
// 문구가 언어에 따라 바뀌므로 const가 아니다 — 화면에서 `const Text(AppStrings.x)`로 쓰지 않는다.

import 'language.dart';

class AppStrings {
  AppStrings._();

  static bool get _isEnglish => isEnglish;
  static String _t(String korean, String english) =>
      _isEnglish ? english : korean;

  static const _englishMonths = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// 영어 문장 가운데에 들어가는 행 목록: "line 6" · "lines 2, 6"
  static String _englishLines(List<int> lines) =>
      '${lines.length == 1 ? 'line' : 'lines'} ${lines.join(', ')}';

  // ── KR / EN 전환 (전 화면 오른쪽 위) ──────────────
  static const languageKorean = 'KR';
  static const languageEnglish = 'EN';
  static String get languageToggleLabel => _t('언어', 'Language');

  // ── 공통 ──────────────────────────────────────
  static String get appName => _t('여백', 'Yeobaek');
  static String get appSubtitle =>
      _t('시 읽기 보조바퀴', 'Training wheels for reading poems');
  static String charCount(int count, int max) => '$count / $max';
  static String lineLabel(int lineNo) => _t('$lineNo행', 'Line $lineNo');
  static String lineList(List<int> lines) => _isEnglish
      ? '${lines.length == 1 ? 'Line' : 'Lines'} ${lines.join(', ')}'
      : lines.map(lineLabel).join(', ');
  static String monthDay(DateTime date) => _t(
        '${date.month}월 ${date.day}일',
        '${_englishMonths[date.month - 1]} ${date.day}',
      );
  static String get close => _t('닫기', 'Close');
  static String stopCount(int count) =>
      _t('$count명', count == 1 ? '1 person' : '$count people');

  // ── 하단 탭바 ─────────────────────────────────
  static String get tabPoems => _t('시', 'Poems');
  static String get tabCommunity => _t('모두의 대화', 'Conversations');
  static String get tabSettings => _t('설정', 'Settings');

  // ── 앱 시작 관문 (로그인 분기) ─────────────────
  static String get authGateFailed => _t(
        '시작하지 못했어요. 인터넷 연결을 확인해 주세요.',
        "Couldn't start. Please check your internet connection.",
      );
  static String get authGateRetry => _t('다시 시도', 'Try again');

  // ── S01 로그인 ────────────────────────────────
  static String get signInEmailLabel => _t('이메일', 'Email');
  static const signInEmailHint = 'example@gmail.com';
  static String get signInPasswordLabel => _t('비밀번호', 'Password');
  static String get signInPasswordHint =>
      _t('비밀번호를 입력하세요', 'Enter your password');
  static String get signInButton => _t('로그인', 'Sign in');
  static String get signInGoogleButton =>
      _t('구글로 시작하기', 'Continue with Google');
  static String get signInOr => _t('또는', 'or');
  static String get signInNoAccount =>
      _t('계정이 없다면', "Don't have an account?");
  static String get signInGoToSignUp => _t('가입하기', 'Sign up');

  // ── S02 가입 ──────────────────────────────────
  static String get signUpTitle => _t('가입하기', 'Sign up');
  static String get signUpHeading =>
      _t('읽은 것을 남기려면', 'To keep what you read');
  static String get signUpSubheading =>
      _t('구글 이메일로 계정을 만듭니다.', 'Create an account with your Gmail address.');
  static String get signUpEmailHelper =>
      _t('gmail.com 주소만 쓸 수 있어요', 'Only gmail.com addresses');
  static String get signUpPasswordHint => _t('6자 이상', 'At least 6 characters');
  static String get signUpPasswordHelper => _t(
        '영문 소문자와 숫자만 쓸 수 있어요',
        'Lowercase letters and numbers only',
      );
  static String get signUpPasswordConfirmLabel =>
      _t('비밀번호 확인', 'Confirm password');
  static String get signUpPasswordConfirmHint =>
      _t('한 번 더 입력하세요', 'Enter it once more');
  static String get signUpPasswordMatch =>
      _t('비밀번호가 일치합니다', 'Passwords match');
  static String get signUpPasswordMismatch =>
      _t('비밀번호가 서로 다릅니다', "Passwords don't match");
  static String get signUpNicknameLabel => _t('닉네임', 'Nickname');
  static String get signUpNicknameNotice => _t(
        '닉네임은 앱이 정해 드립니다. 새로고침하면 바뀝니다.',
        'The app picks a nickname for you. Refresh to get another.',
      );
  static String get signUpNicknameRefresh =>
      _t('다른 닉네임', 'Another nickname');
  static String get signUpButton => _t('가입하기', 'Sign up');
  static String get signUpHaveAccount =>
      _t('이미 계정이 있다면', 'Already have an account?');
  static String get signUpGoToSignIn => _t('로그인', 'Sign in');
  static String get signUpEmailInvalid =>
      _t('gmail.com 주소를 입력해 주세요', 'Please enter a gmail.com address');
  static String signUpPasswordTooShort(int min) =>
      _t('$min자 이상 입력해 주세요', 'Please enter at least $min characters');
  static String signUpNicknameAdjusted(String nickname) => _t(
        '같은 닉네임이 있어서 「$nickname」(으)로 정했어요',
        'That nickname was taken, so you are “$nickname”',
      );

  // ── S02 닉네임만 정하기 (구글로 처음 들어온 사람) ──
  static String get nicknameOnlyTitle => _t('닉네임 정하기', 'Choose a nickname');
  static String get nicknameOnlyHeading => _t('처음 오셨네요', 'Welcome');
  static String get nicknameOnlySubheading => _t(
        '여백에서 쓸 닉네임을 정해 주세요.',
        'Choose the nickname you will use on Yeobaek.',
      );
  static String get nicknameOnlyButton => _t('시작하기', 'Get started');
  static String get nicknameOnlyOtherAccount =>
      _t('다른 계정으로 로그인', 'Sign in with another account');

  // ── 로그인 · 가입 오류 ─────────────────────────
  static String get authErrorInvalidCredentials =>
      _t('이메일이나 비밀번호가 맞지 않아요', 'Email or password is wrong');
  static String get authErrorEmailInUse => _t(
        '이미 가입된 이메일이에요. 로그인해 주세요',
        'This email is already registered. Please sign in',
      );
  static String get authErrorNotGmail =>
      _t('gmail.com 계정만 쓸 수 있어요', 'Only gmail.com accounts can be used');
  static String get authErrorNetwork =>
      _t('인터넷 연결을 확인해 주세요', 'Please check your internet connection');
  static String get authErrorUnknown =>
      _t('잠시 후 다시 시도해 주세요', 'Please try again in a moment');

  // ── S03 홈 (B) ────────────────────────────────
  static String homeTotalDays(int days) => _t(
        '지금까지 $days일 시를 읽었어요',
        days == 1
            ? "You've read poems on 1 day so far"
            : "You've read poems on $days days so far",
      );
  static String get homeProfileTooltip => _t('내 프로필', 'My profile');
  static String get homeTodayPoem => _t('오늘의 시', "Today's poem");
  static String get homeStartReading => _t('혼자 읽기 시작', 'Start reading alone');
  static String get homePoemList => _t('시 목록', 'Poems');
  static String get homeReadMark => _t('읽음', 'Read');
  static String get homeContinueTitle => _t('이어 읽기', 'Keep reading');
  static String homeContinueSubtitle(String firstWord) => _t(
        '‘$firstWord’에서 시작한 대화를 이어 가요',
        'Continue the conversation that began with ‘$firstWord’',
      );

  // ── S04 읽기 ──────────────────────────────────
  static String readingAppBarTitle(String author, String title) =>
      _t('$author 「$title」', '$author, “$title”');
  static String readingAuthorYear(String author, int year) => '$author · $year';
  static String get readingStopGuide => _t(
        '마음이 멈춘 줄을 눌러 보세요. 아무것도 안 눌러도 됩니다.',
        'Tap a line where your mind paused. You can also tap nothing.',
      );
  static String get readingMarkFailed => _t(
        '표시하지 못했어요. 잠시 뒤에 다시 눌러 주세요.',
        "Couldn't mark it. Please tap again in a moment.",
      );
  static String get readingFirstWordLabel =>
      _t('읽고 떠오른 낱말 하나', 'One word that came to mind');
  static String get readingFirstWordFixed => _t(
        '이 낱말에서 대화를 시작했어요.',
        'You started the conversation with this word.',
      );
  static String get readingStartChat =>
      _t('이 낱말로 대화 시작', 'Start a conversation with this word');
  static String get readingContinueChat =>
      _t('대화 이어 하기', 'Continue the conversation');
  static String get readingEndWithWord =>
      _t('낱말만 남기고 끝내기', 'Just keep the word and finish');

  // ── S05 대화 ──────────────────────────────────
  static String chatTitle(String title) =>
      _t('$title — 읽는 중', '$title — reading');
  static String get chatHintButton => _t('힌트 더 주세요', 'Give me a hint');
  static String get chatHintTitle => _t('시에서 찾아볼 것', 'Look for this in the poem');
  static String get chatSummarizeButton =>
      _t('내 해석 정리하기', 'Gather my interpretation');
  static String get chatInputHint => _t('생각을 적어 보세요', 'Write your thoughts');
  static String get chatSendButton => _t('보내기', 'Send');
  static String get chatStopButton => _t('중단', 'Stop');
  static String get chatResponding =>
      _t('질문을 고르는 중…', 'Choosing a question…');

  // ── S06 정리 · 저장 (B) ────────────────────────
  static String get saveTitle => _t('내 해석', 'My interpretation');
  static String get saveDraftNotice => _t(
        '대화에서 나온 내 말을 모았습니다. 고쳐서 저장하세요 — 저장하는 문장은 당신 것이어야 합니다.',
        'We gathered your own words from the conversation. Edit them and save — the sentences you save should be yours.',
      );
  static String get saveEvidenceLabel =>
      _t('내가 근거로 삼은 구절', 'Lines I based it on');
  static String get savePublicLabel =>
      _t('대화를 모두의 대화에 공개', 'Share this conversation in Conversations');
  static String get savePublicCaption => _t(
        'AI가 대화에서 의미 있는 내용만 뽑아 닉네임과 함께 올립니다',
        'AI picks out the meaningful parts and posts them with your nickname',
      );
  static String get savePublicFixed => _t(
        '이미 공개한 대화는 되돌릴 수 없어요.',
        "A conversation you've shared can't be unshared.",
      );
  static String get saveLockNotice => _t(
        '저장한 뒤에야 전문가 해석과 다른 사람의 대화가 열립니다.',
        "Expert interpretations and others' conversations open only after you save.",
      );
  static String get saveButton => _t('저장하기', 'Save');
  static String get saveLockedNotice => _t(
        '대조를 연 뒤라 해석은 더 고칠 수 없어요.',
        "You've opened the comparison, so the interpretation can no longer be edited.",
      );
  static String get saveFailed =>
      _t('저장하지 못했어요. 다시 눌러 주세요.', "Couldn't save. Please tap again.");
  static String get saveKeptForLater => _t(
        '지금은 저장하지 못해서 기기에 보관해 뒀어요. 다음에 앱을 열면 다시 저장할게요.',
        "Couldn't save right now, so it's kept on this device. We'll save it next time you open the app.",
      );
  static String get homePendingSaved =>
      _t('보관해 둔 해석을 저장했어요.', 'Saved the interpretation kept on this device.');

  // ── S07 대조 (D) ──────────────────────────────
  static String comparisonTitle(String poemTitle) =>
      _t('$poemTitle — 대조', '$poemTitle — comparison');
  static String comparisonPoemInfo(String title, String author, int year) =>
      '$title · $author ($year)';
  static String comparisonMyEvidence(List<int> lines) =>
      _t('내 근거: ${lineList(lines)}', 'My evidence: ${lineList(lines)}');
  static String get comparisonMine => _t('내 해석', 'My interpretation');
  static String get comparisonMineCaption =>
      _t('내가 직접 다듬어 저장한 생각', 'Thoughts I refined and saved myself');
  static String get comparisonRelationSameLines =>
      _t('같은 곳을 봤어요', 'We looked at the same place');
  static String get comparisonRelationPartialOverlap =>
      _t('같은 줄에서 출발했어요', 'We started from the same line');
  static String comparisonRelationDifferentLines(List<int> lines) => _t(
        '이 해석은 ${lines.join(', ')}행을 중심으로 읽었어요',
        'This interpretation centers on ${_englishLines(lines)}',
      );
  static String get comparisonNoExperts => _t(
        '이 시의 전문가 해석은 준비 중이에요.',
        'Expert interpretations for this poem are being prepared.',
      );

  /// 비교 문장을 모델이 쓰지 못했을 때 (키 없음 · 실패 · 취소).
  /// 공통점부터 말하고, 내가 놓친 것을 가리키지 않는다 (기획서 4장).
  static String comparisonFallbackSameLines(List<int> lines) => _t(
        '두 읽기 모두 ${lines.join(', ')}행을 근거로 삼았어요.',
        'Both readings draw on ${_englishLines(lines)}.',
      );
  static String comparisonFallbackPartialOverlap(List<int> lines) => _t(
        '두 읽기 모두 ${lines.join(', ')}행을 지나가요.',
        'Both readings pass through ${_englishLines(lines)}.',
      );
  static String get comparisonFallbackDifferentLines => _t(
        '두 읽기는 서로 다른 줄에서 출발해요.',
        'The two readings start from different lines.',
      );
  static String get comparisonCreationBackground =>
      _t('창작 배경 보기', 'How the poem was written');
  static String get comparisonCreationBackgroundTitle =>
      _t('창작 배경', 'Background');
  static String get comparisonGoCommunity =>
      _t('다른 사람의 대화 보기', "See others' conversations");

  // ── S08 대화 목록 (D) ─────────────────────────
  static String get communityTitle => _t('모두의 대화', 'Conversations');
  static String get communityEmpty =>
      _t('아직 공개된 대화가 없어요.', 'No shared conversations yet.');
  static String communityFirstWordTag(String word) => '#$word';

  /// 잠금 — 그 시의 해석을 저장해야 남의 대화가 열린다 (기획서 5장 「잠금 한 곳」)
  static String get communityLockedTitle =>
      _t('아직 열리지 않았어요', 'Not open yet');
  static String get communityLockedBody => _t(
        '이 시를 끝까지 읽고 내 해석을 저장하면 다른 사람의 대화가 열려요.',
        "Read this poem through and save your interpretation to open others' conversations.",
      );
  static String get communityLockedAction =>
      _t('이 시 읽으러 가기', 'Go read this poem');

  /// 읽어 오지 못했을 때. 이유를 단정하지 않는다 — 잠금일 수도, 네트워크일
  /// 수도 있다. 화면이 영원히 도는 것보다 낫다.
  static String get noticeUnavailable =>
      _t('지금은 가져올 수 없어요.', "Can't load this right now.");
  static String get noticeUnavailableAction => _t('다시 시도', 'Try again');

  // ── S09 대화 보기 (D) ─────────────────────────
  static String communityDetailTitle(String poemTitle) =>
      _t('$poemTitle · 읽은이의 대화', "$poemTitle · A reader's conversation");
  static String get communityDetailFirstWord => _t('1. 첫 낱말', '1. First word');
  static String get communityDetailFirstWordCaption => _t(
        '시를 읽고 가장 먼저 떠올린 말',
        'The first word that came to mind after reading',
      );
  static String get communityDetailFirstWordNote => _t(
        '이 낱말에서 AI와의 대화가 시작되었습니다.',
        'The conversation with AI began from this word.',
      );
  static String get communityDetailSummary =>
      _t('2. 대화 과정', '2. How the conversation went');

  /// 요약을 모델이 쓰지 못했을 때 (키 없음 · 실패 · 취소). 사실만 적는다.
  /// 요약은 한국어 · 영어 두 벌로 저장되는 글이라, 화면 언어가 아니라 [language]로 쓴다.
  static String communitySummaryFallback(
    String firstWord,
    int questionCount, {
    required AppLanguage language,
  }) {
    final english = language == AppLanguage.en;
    if (questionCount > 0) {
      if (!english) return '「$firstWord」에서 시작해 질문 $questionCount개를 지난 대화예요.';
      return questionCount == 1
          ? 'A conversation that began with “$firstWord” and went through 1 question.'
          : 'A conversation that began with “$firstWord” and went through $questionCount questions.';
    }
    return english
        ? 'A conversation that began with “$firstWord”.'
        : '「$firstWord」에서 시작한 대화예요.';
  }
  static String get communityDetailSummaryCaption =>
      _t('AI 질문과 사유의 요약', "A summary of AI's questions and the reader's thinking");
  static String communityDetailEvidence(List<int> lines) => _t(
        '확인된 근거 구절: ${lineList(lines)}',
        'Confirmed evidence: ${lineList(lines)}',
      );
  static String get communityDetailInterpretation =>
      _t('3. 최종 해석', '3. Final interpretation');
  static String get communityDetailInterpretationCaption => _t(
        '대화를 거쳐 도달한 고유한 생각',
        'A thought of their own, reached through the conversation',
      );
  static String communityDetailEmpathyCount(int count) =>
      _t('공감 $count', 'Empathy $count');
  static String get communityDetailEmpathyNote => _t(
        '공감은 우열이나 순위에 반영되지 않습니다.',
        'Empathy is never used for ranking or rating.',
      );
  static String get communityDetailEmpathyFailed => _t(
        '공감을 저장하지 못했어요. 잠시 뒤 다시 눌러 주세요.',
        "Couldn't save your empathy. Please tap again in a moment.",
      );

  // ── S10 설정 보기 ─────────────────────────────
  static String get settingsTitle => _t('설정', 'Settings');
  static String get settingsModelSection => _t('AI 모델', 'AI models');
  static String get settingsQuestionModel => _t('질문 · 힌트', 'Questions · Hints');
  static String get settingsComparisonModel =>
      _t('비교 · 요약', 'Comparison · Summary');
  static String get settingsModelCaption => _t(
        '질문에는 신중한 모델, 비교와 요약에는 빠른 모델을 써요.',
        'A careful model asks questions; a fast model compares and summarizes.',
      );
  static String get settingsToneSection => _t('AI 말투', 'AI tone');
  static String get settingsUsageSection => _t('이번 달 사용량', 'Usage this month');
  static String settingsUsage(int questionCount, int comparisonCount) => _t(
        '질문 $questionCount회 · 비교 $comparisonCount회',
        'Questions $questionCount · Comparisons $comparisonCount',
      );
  static String get settingsEditButton => _t('설정 바꾸기', 'Change settings');
  static String get settingsLoadFailed => _t(
        '설정을 불러오지 못했어요. 잠시 후 다시 열어 주세요.',
        "Couldn't load settings. Please open this again in a moment.",
      );
  static String get settingsSignOut => _t('로그아웃', 'Sign out');
  static String get settingsSignOutDialogTitle =>
      _t('로그아웃할까요?', 'Sign out?');
  static String get settingsSignOutDialogBody => _t(
        '다시 로그인하면 읽은 기록은 그대로 있어요.',
        'Your reading history will still be here when you sign back in.',
      );
  static String get settingsSignOutCancel => _t('취소', 'Cancel');
  static String get settingsSignOutFailed => _t(
        '로그아웃하지 못했어요. 잠시 후 다시 해 주세요.',
        "Couldn't sign out. Please try again in a moment.",
      );

  // ── S11 설정 바꾸기 ───────────────────────────
  static String get settingsEditTitle => _t('설정 바꾸기', 'Change settings');
  static String get settingsEditQuestionModel =>
      _t('질문을 만들 때 쓸 모델', 'Model for asking questions');
  static String get settingsEditComparisonModel =>
      _t('비교할 때 쓸 모델', 'Model for comparing');
  static String get settingsEditTone => _t('AI 말투', 'AI tone');
  static String get settingsEditDeleteHistory =>
      _t('대화 기록 지우기', 'Delete conversation history');
  static String get settingsEditDeleteAction => _t('지우기', 'Delete');
  static String get settingsEditSave => _t('저장', 'Save');
  static String get settingsEditDeleteHistoryCaption => _t(
        '저장한 해석과 뱃지는 남아요.',
        'Saved interpretations and badges stay.',
      );
  static String get settingsEditSaved => _t('설정을 저장했어요.', 'Settings saved.');
  static String get settingsEditSaveFailed => _t(
        '저장하지 못했어요. 잠시 후 다시 해 주세요.',
        "Couldn't save. Please try again in a moment.",
      );
  static String get settingsDeleteDialogTitle =>
      _t('대화 기록을 지울까요?', 'Delete conversation history?');
  static String get settingsDeleteDialogBody => _t(
        '모든 시에서 AI와 나눈 대화가 지워지고, 되돌릴 수 없어요.\n'
            '저장한 해석, 뱃지, 시를 읽은 날, 공개한 대화는 그대로 남아요.',
        'Your conversations with AI on every poem will be deleted. This cannot be undone.\n'
            'Saved interpretations, badges, reading days and shared conversations stay.',
      );
  static String get settingsDeleteCancel => _t('취소', 'Cancel');
  static String get settingsDeleteDone =>
      _t('대화 기록을 지웠어요.', 'Conversation history deleted.');
  static String get settingsDeleteFailed => _t(
        '지우지 못했어요. 잠시 후 다시 해 주세요.',
        "Couldn't delete. Please try again in a moment.",
      );

  // 말투 (S10 · S11 공용)
  static String get tonePlain => _t('담백하게', 'Plain');
  static String get toneGentle => _t('부드럽게', 'Gentle');

  // ── S12 프로필 (D) ────────────────────────────
  static String get profileMyTitle => _t('내 선반', 'My shelf');
  static String profileOtherTitle(String nickname) =>
      _t('$nickname의 선반', "$nickname's shelf");
  static String get profileEmailLinked =>
      _t('이메일 계정으로 연결됨', 'Linked to an email account');
  static String get profileTotalDaysLabel => _t('시를 읽은 날', 'Days reading poems');
  static String get profileBadges => _t('모은 시 뱃지', 'Poem badges');
  static String profileBadgeCount(int count) => _t('$count개', '$count');
  static String get profileBadgesCaption => _t(
        '끝까지 읽고 생각을 저장한 시마다 그 시를 닮은 뱃지가 남습니다.',
        'Each poem you read through and save your thoughts on leaves a badge that resembles it.',
      );
  static String get profileNoBadges => _t(
        '아직 모은 뱃지가 없습니다.\n시를 읽고 해석을 저장해 보세요.',
        'No badges yet.\nRead a poem and save your interpretation.',
      );
  static String get profileShelfNote => _t(
        '프로필은 당신의 생각을 모아두는 조용한 선반입니다.',
        'Your profile is a quiet shelf that holds your thoughts.',
      );

  // ── S13 안내 ──────────────────────────────────
  static String get introStart => _t('시 읽으러 가기', 'Go read poems');
  static String get introSkip => _t('건너뛰기', 'Skip');
  static String get introLinesTitle => _t('마음에 남은 줄', 'Lines that stayed with you');
  static String get introLinesEmpty => _t(
        '시를 한 편 읽고 나면, 가장 마음에 남은 줄이 여기에 남습니다.',
        'After you read a poem, the line that stayed with you most will appear here.',
      );
  static String get introStatusTitle => _t('지금까지', 'So far');
  static String introDays(int count) => _t(
        '시를 읽은 날 $count일',
        count == 1 ? '1 day reading poems' : '$count days reading poems',
      );
  static String introShared(int count) => _t(
        '모두에게 나눈 글 $count편',
        count == 1 ? '1 piece shared with everyone' : '$count pieces shared with everyone',
      );
  static String introBadges(int count) => _t(
        '받은 뱃지 $count개',
        count == 1 ? '1 badge earned' : '$count badges earned',
      );

  // ── 로딩 (S06 → S07 전환, D) ──────────────────
  /// 기다리는 동안 보이는 글자. 한 글자씩 파도치듯 튄다 (AppLoading).
  /// 글자 수가 바뀌면 파도 길이도 그만큼 바뀐다 — 마음껏 줄이고 늘려도 된다.
  /// 이미 영어라 KR / EN 모두 같다. AppLoading의 const 기본값으로 쓰여서 const로 둔다.
  static const loadingLabel = 'LOADING......';

  /// 글자 아래 한 줄. S06에서 저장을 누르고 S07 대조가 열리기까지가 이 앱에서
  /// 가장 긴 기다림이라(저장소 쓰기 + 모델이 비교 문장을 쓰는 시간) 무엇을
  /// 기다리는지 적어 둔다. 로딩 화면은 지금 이 한 자리에서만 쓴다.
  static String get loadingSavingConversation =>
      _t('대화를 저장소에 저장하고 있어요', 'Saving your conversation');
}
