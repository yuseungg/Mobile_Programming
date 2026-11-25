// 주인: B — 계절 테마 (docs/여백-테마설계.md 1 · 2 · 4장)
// 시마다 계절이 하나 있고 그 시를 다루는 화면은 그 계절 색 · 그림으로 바뀜
// 화면에서 계절을 직접 고르지 말고 YeobaekTheme.forPoem(poemId)로 받아 씀
import 'package:flutter/material.dart';

enum Season { basic, spring, autumn, winter }

class YeobaekTheme {
  const YeobaekTheme({
    required this.season,
    required this.background,
    required this.card,
    required this.headerTint,
    required this.seasonAccent,
    required this.headerImage,
    required this.mascot,
  });

  final Season season;
  final Color background;
  final Color card;
  final Color headerTint; // 머리 띠 그림 못 불러올 때 단색
  final Color seasonAccent; // 칩 · 작은 장식
  final String headerImage; // 가로 3 : 세로 1
  final String mascot;

  static const defaults = YeobaekTheme(
    season: Season.basic,
    background: Color(0xFFFDF7EE),
    card: Color(0xFFFFFFFF),
    headerTint: Color(0xFFAEEFFD),
    seasonAccent: Color(0xFFE04A2F),
    headerImage: 'assets/images/header_default.jpg',
    mascot: 'assets/images/mascot_default.png',
  );

  static const spring = YeobaekTheme(
    season: Season.spring,
    background: Color(0xFFFDF2F4),
    card: Color(0xFFFDEDEE),
    headerTint: Color(0xFFF9D6E0),
    seasonAccent: Color(0xFFE98AA6),
    headerImage: 'assets/images/header_spring.jpg',
    mascot: 'assets/images/mascot_spring.png',
  );

  static const autumn = YeobaekTheme(
    season: Season.autumn,
    background: Color(0xFFF8EDDD),
    card: Color(0xFFF7E9D7),
    headerTint: Color(0xFFFBDBBC),
    seasonAccent: Color(0xFFF0883A),
    headerImage: 'assets/images/header_autumn.jpg',
    mascot: 'assets/images/mascot_autumn.png',
  );

  static const winter = YeobaekTheme(
    season: Season.winter,
    background: Color(0xFFEEF4FC),
    card: Color(0xFFE7F1F9),
    headerTint: Color(0xFFCAE3FA),
    seasonAccent: Color(0xFF7FB3E3),
    headerImage: 'assets/images/header_winter.jpg',
    mascot: 'assets/images/mascot_winter.png',
  );

  static const all = [defaults, spring, autumn, winter];

  // 진달래꽃 · 봄은 고양이로다 = 봄, 서시 = 겨울, The Road Not Taken = 가을
  // 시 새로 넣으면 여기도 추가 (안 넣거나 모르는 id면 기본)
  static YeobaekTheme forPoem(String poemId) {
    switch (poemId) {
      case 'jindallae':
      case 'bomgoyangi':
        return spring;
      case 'seosi':
        return winter;
      case 'theroadnottaken':
        return autumn;
    }
    return defaults;
  }
}

/// 계절이랑 상관없는 그림 (테마설계 2장)
class AppImages {
  AppImages._();

  static const logo = 'assets/images/logo_yeobaek.png'; // S01 · S03 · S13
  static const shelf = 'assets/images/shelf.png'; // S12 뱃지 선반
  static const paper = 'assets/images/paper_texture.jpg'; // 시 화면 배경. 한 장을 늘려 깔 것 (반복하면 이음새 보임)

  // 상태 마스코트 — MascotNotice에서 씀
  static const mascotLocked = 'assets/images/mascot_locked.png'; // 저장 전 잠금 (S07 · S08 · S09)
  static const mascotEmpty = 'assets/images/mascot_empty.png'; // 빈 화면
  static const mascotError = 'assets/images/mascot_error.png'; // 오류 · 연결 끊김
}
