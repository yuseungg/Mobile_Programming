// 주인: A
// 색·글꼴은 여기서만 정한다. 화면 파일 안에 색 코드(Color(0x…))를 직접 쓰지 않는다.
// 기준: docs/여백-기획서최종.md 부록 B 디자인 토큰
import 'package:flutter/material.dart';

/// 디자인 토큰 — 색
class AppColors {
  AppColors._();

  static const background = Color(0xFFE8EAE2); // 배경
  static const card = Color(0xFFFBFBF7); // 카드
  static const input = Color(0xFFF1F2EC); // 입력 배경
  static const text = Color(0xFF1E3038); // 본문
  static const textSub = Color(0xFF5D6F74); // 보조 텍스트
  static const textFaint = Color(0xFF8B9A9C); // 흐린 텍스트
  static const border = Color(0xFFC9CFC3); // 테두리
  static const accent = Color(0xFF8A3A50); // 사용자 · 강조 (와인)
  static const accentBg = Color(0xFFF3E6E9); // 사용자 배경
  static const confirmed = Color(0xFF3D6B52); // 확인됨 (초록)
  static const info = Color(0xFF3B5470); // 정보
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
        borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
      ),
    ),
    // 주 버튼은 먹색(본문색). 와인은 '저장하기'처럼 잠금을 여는 순간에만 쓴다 (목업 기준).
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.text,
        foregroundColor: AppColors.card,
        minimumSize: const Size.fromHeight(52),
        textStyle: AppText.button,
        shape: RoundedRectangleBorder(borderRadius: radius12),
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
        foregroundColor: AppColors.accent,
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
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.text,
      contentTextStyle: AppText.body.copyWith(color: AppColors.card),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
