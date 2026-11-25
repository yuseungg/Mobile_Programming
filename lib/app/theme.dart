// 주인: A
// 색·글꼴은 여기서만 정한다. 화면 파일 안에 색 코드(Color(0x…))를 직접 쓰지 않는다.
// 기준: docs/여백-기획서최종.md 부록 B 디자인 토큰
import 'package:flutter/material.dart';

/// 디자인 토큰 — 색
/// 하늘색 · 병아리 시안 (docs/여백-테마설계.md 3장). 이름은 그대로 두고 값만 바꿈
/// background · card는 시마다 다름 → 여기엔 기본 테마 값, 계절 값은 poem_theme.dart
class AppColors {
  AppColors._();

  static const background = Color(0xFFFDF7EE); // 배경 (기본 테마)
  static const card = Color(0xFFFFFFFF); // 카드 (기본 테마)
  static const input = Color(0xFFFFFDF8); // 입력 배경
  static const text = Color(0xFF0B4F4C); // 본문 · 제목 (짙은 청록)
  static const textSub = Color(0xFF5E7572); // 보조 텍스트
  static const textFaint = Color(0xFF93A3A0); // 흐린 텍스트 · 행 번호
  static const border = Color(0xFFE3DACB); // 테두리 · 구분선
  static const accent = Color(0xFFEE5A24); // 주요 버튼 · 사용자 강조 (주황)
  static const accentDark = Color(0xFFD2481A); // 주황 버튼 아래 두께
  static const accentBg = Color(0xFFFDE8DE); // 내 말풍선 · 선택된 탭 배경
  static const confirmed = Color(0xFF1AA89F); // 확인된 근거 행 · 입력 칸 강조 테두리 (청록)
  static const info = Color(0xFF036963); // 보조 버튼 · 정보
  static const link = Color(0xFFE5482A); // 「가입하기」 같은 글 링크
}

/// 디자인 토큰 — 글꼴
/// 명조: 시 본문, 시 제목, 사용자가 쓴 해석, 앱 이름
/// 고딕: AI 메시지, UI 라벨, 버튼, 설명
class AppFonts {
  AppFonts._();

  static const myeongjo = 'NanumMyeongjo';
  static const gothic = 'NotoSansKR';
}

/// 글자 스타일 모음. 화면에서는 이 스타일만 가져다 쓴다.
class AppText {
  AppText._();

  // ── 명조 (시의 편) ──────────────────────────────
  static const appName = TextStyle(
    fontFamily: AppFonts.myeongjo,
    fontSize: 44,
    fontWeight: FontWeight.w700,
    letterSpacing: 6,
    color: AppColors.text,
  );
  static const appNameSmall = TextStyle(
    fontFamily: AppFonts.myeongjo,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: 3,
    color: AppColors.text,
  );
  static const poemTitle = TextStyle(
    fontFamily: AppFonts.myeongjo,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );
  static const poemTitleSmall = TextStyle(
    fontFamily: AppFonts.myeongjo,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );
  static const poemLine = TextStyle(
    fontFamily: AppFonts.myeongjo,
    fontSize: 17,
    height: 2.0,
    color: AppColors.text,
  );
  static const poemLineCompact = TextStyle(
    fontFamily: AppFonts.myeongjo,
    fontSize: 14,
    height: 1.8,
    color: AppColors.text,
  );
  static const interpretation = TextStyle(
    fontFamily: AppFonts.myeongjo,
    fontSize: 16,
    height: 1.85,
    color: AppColors.text,
  );
  static const interpretationLarge = TextStyle(
    fontFamily: AppFonts.myeongjo,
    fontSize: 17,
    height: 1.9,
    color: AppColors.text,
  );
  static const poemQuote = TextStyle(
    fontFamily: AppFonts.myeongjo,
    fontSize: 15,
    height: 1.6,
    color: AppColors.textSub,
  );
  static const firstWord = TextStyle(
    fontFamily: AppFonts.myeongjo,
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColors.accent,
  );

  /// 사용자 해석을 작게 (대조 화면, 공개 대화 상세)
  static const interpretationSmall = TextStyle(
    fontFamily: AppFonts.myeongjo,
    fontSize: 15,
    height: 1.6,
    color: AppColors.text,
  );

  /// 사용자 해석 미리보기 (공개 대화 카드, 두 줄 자르기)
  static const interpretationPreview = TextStyle(
    fontFamily: AppFonts.myeongjo,
    fontSize: 13,
    height: 1.4,
    color: AppColors.text,
  );

  /// 프로필 동그라미 안의 닉네임 첫 글자
  static const avatarInitial = TextStyle(
    fontFamily: AppFonts.myeongjo,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.accent,
  );

  // ── 고딕 (앱의 편) ──────────────────────────────
  static const userMessage = TextStyle(
    fontFamily: AppFonts.gothic,
    fontSize: 14,
    height: 1.6,
    color: AppColors.accent,
  );
  static const screenTitle = TextStyle(
    fontFamily: AppFonts.gothic,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );
  static const heading = TextStyle(
    fontFamily: AppFonts.gothic,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.4,
    color: AppColors.text,
  );
  static const label = TextStyle(
    fontFamily: AppFonts.gothic,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textSub,
  );
  static const body = TextStyle(
    fontFamily: AppFonts.gothic,
    fontSize: 15,
    height: 1.6,
    color: AppColors.text,
  );
  static const bodyStrong = TextStyle(
    fontFamily: AppFonts.gothic,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.6,
    color: AppColors.text,
  );
  static const bodySub = TextStyle(
    fontFamily: AppFonts.gothic,
    fontSize: 14,
    height: 1.6,
    color: AppColors.textSub,
  );
  static const aiMessage = TextStyle(
    fontFamily: AppFonts.gothic,
    fontSize: 14,
    height: 1.6,
    color: AppColors.text,
  );
  static const caption = TextStyle(
    fontFamily: AppFonts.gothic,
    fontSize: 12,
    height: 1.5,
    color: AppColors.textFaint,
  );
  static const lineNumber = TextStyle(
    fontFamily: AppFonts.gothic,
    fontSize: 11,
    color: AppColors.textFaint,
  );
  static const stopCount = TextStyle(
    fontFamily: AppFonts.gothic,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.accent,
  );
  static const relation = TextStyle(
    fontFamily: AppFonts.gothic,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.info,
  );
  static const confirmedNotice = TextStyle(
    fontFamily: AppFonts.gothic,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.confirmed,
  );
  static const warningNotice = TextStyle(
    fontFamily: AppFonts.gothic,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.accent,
  );

  /// 카드 제목 (공개 대화 카드 등)
  static const cardTitle = TextStyle(
    fontFamily: AppFonts.gothic,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );

  /// 화면 안 구역 제목
  static const sectionTitle = TextStyle(
    fontFamily: AppFonts.gothic,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );

  /// 프로필 닉네임. 값은 화면 제목과 같다.
  static const profileName = screenTitle;

  /// 와인 배경 위의 작은 태그 글자 (예: 대조 화면의 「나」)
  static const tagOnAccent = TextStyle(
    fontFamily: AppFonts.gothic,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.card,
  );

  /// 근거 행 번호 태그 (초록 = 확인됨)
  static const evidenceTag = TextStyle(
    fontFamily: AppFonts.gothic,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.confirmed,
  );

  /// 첫 낱말 태그 (공개 대화 카드)
  static const firstWordTag = TextStyle(
    fontFamily: AppFonts.gothic,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.accent,
  );

  /// 받은 뱃지 개수 (프로필)
  static const badgeCount = TextStyle(
    fontFamily: AppFonts.gothic,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.accent,
  );

  /// 흐린 안내문, 기울임 (프로필 선반 아래)
  static const captionItalic = TextStyle(
    fontFamily: AppFonts.gothic,
    fontSize: 12,
    height: 1.5,
    fontStyle: FontStyle.italic,
    color: AppColors.textFaint,
  );

  static const button = TextStyle(
    fontFamily: AppFonts.gothic,
    fontSize: 15,
    fontWeight: FontWeight.w500,
  );
}

/// 앱 전체 테마
ThemeData buildAppTheme() {
  final radius12 = BorderRadius.circular(12);

  return ThemeData(
    useMaterial3: true,
    fontFamily: AppFonts.gothic,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.light(
      primary: AppColors.accent,
      onPrimary: AppColors.card,
      secondary: AppColors.info,
      onSecondary: AppColors.card,
      surface: AppColors.card,
      onSurface: AppColors.text,
      onSurfaceVariant: AppColors.textSub,
      outline: AppColors.border,
      outlineVariant: AppColors.border,
      error: AppColors.accent,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: AppText.screenTitle,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 1,
      space: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.input,
      hintStyle: AppText.bodySub.copyWith(color: AppColors.textFaint),
      helperStyle: AppText.caption,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: radius12,
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius12,
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius12,
        borderSide: const BorderSide(color: AppColors.confirmed, width: 2),
      ),
    ),
    // 주요 버튼은 주황 + 아래 두께 (테마설계 3장)
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        textStyle: AppText.button,
        shape: RoundedRectangleBorder(borderRadius: radius12),
      ).copyWith(
        // 아래 두께는 버튼 안 아래쪽에 깔아서 그림 (shape로는 아래만 두껍게가 안 됨)
        // 두께 색이 주황 고정이라 화면에서 버튼 색을 딴 색으로 바꾸면 안 맞음 (지금은 다 주황)
        backgroundBuilder: (context, states, child) {
          if (states.contains(WidgetState.disabled)) {
            return child ?? const SizedBox();
          }
          return ClipRRect(
            borderRadius: radius12,
            child: Stack(
              fit: StackFit.passthrough, // 안 하면 글자가 위로 붙음
              children: [
                ?child,
                const Positioned(left: 0, right: 0, bottom: 0, height: 4,
                    child: ColoredBox(color: AppColors.accentDark)),
              ],
            ),
          );
        },
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.text,
        backgroundColor: AppColors.card,
        minimumSize: const Size.fromHeight(52),
        textStyle: AppText.button,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: radius12),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        backgroundColor: AppColors.card,
        foregroundColor: AppColors.textSub,
        selectedBackgroundColor: AppColors.text,
        selectedForegroundColor: AppColors.card,
        side: const BorderSide(color: AppColors.border),
        textStyle: AppText.button,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.link,
        textStyle: AppText.button,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.card,
      indicatorColor: AppColors.accentBg,
      surfaceTintColor: AppColors.card,
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => AppText.label.copyWith(
          color: states.contains(WidgetState.selected)
              ? AppColors.accent
              : AppColors.textSub,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? AppColors.accent
              : AppColors.textSub,
        ),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.card
            : AppColors.textFaint,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.accent
            : AppColors.input,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.accent
            : AppColors.border,
      ),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.accent
            : AppColors.textFaint,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.card,
      selectedColor: AppColors.accentBg,
      side: const BorderSide(color: AppColors.border),
      labelStyle: AppText.bodyStrong,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.card,
      surfaceTintColor: AppColors.card,
      showDragHandle: true,
    ),
    // 확인 창 (S10 로그아웃 · S11 기록 지우기). 없으면 제목이 Material 기본 크기로 커진다
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.card,
      surfaceTintColor: AppColors.card,
      titleTextStyle: AppText.screenTitle,
      contentTextStyle: AppText.body,
      shape: RoundedRectangleBorder(borderRadius: radius12),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.text,
      contentTextStyle: AppText.body.copyWith(color: AppColors.card),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
