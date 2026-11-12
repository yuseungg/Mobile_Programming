// 주인: D — 전문가 해석 파일 읽기 (기획서 7장 「전문가 해석 형식」)
//
// 전문가 해석은 코드가 아니라 앱 번들 JSON에 있다. 시를 추가할 때
// 본문 JSON · 전문가 해석 · 뱃지 이미지가 한 세트로 들어간다 (기획서 11장).
//
// 파싱(parseExpertFile)과 읽기(loadExpertFile)를 나눠 둔다. 파싱은 순수해서
// 문자열만으로 테스트할 수 있고, 읽기만 에셋을 건드린다.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../data/models/expert_interpretation.dart';

/// 시 한 편의 전문가 해석 파일 한 개
class ExpertFile {
  const ExpertFile({
    required this.poemId,
    required this.badgePath,
    required this.readings,
  });

  final String poemId;

  /// 뱃지 이미지 경로. 파일 안에서는 `badges/seosi.png`처럼 적고,
  /// 에셋으로 읽을 때는 `assets/`를 앞에 붙인다.
  final String badgePath;

  final List<ExpertInterpretation> readings;

  /// 에셋 경로 — `assets/badges/seosi.png`
  String get badgeAssetPath => 'assets/$badgePath';
}

/// 전문가 해석 파일의 에셋 경로
String expertAssetPath(String poemId) => 'assets/poems/$poemId.json';

/// JSON 문자열을 읽는다. 형식이 어긋나면 [FormatException]을 던진다.
///
/// 주장마다 근거 행이 붙어 있어야 코드가 관계를 계산할 수 있으므로,
/// 근거 행이 없는 주장은 형식 오류로 본다 (기획서 7장).
ExpertFile parseExpertFile(String source) {
  final Object? decoded = jsonDecode(source);
  if (decoded is! Map<String, Object?>) {
    throw const FormatException('전문가 해석 파일의 최상위는 객체여야 한다');
  }

  final poemId = _requireText(decoded, 'poem');
  final badgePath = _requireText(decoded, 'badge');

  final rawReadings = decoded['readings'];
  if (rawReadings is! List) {
    throw const FormatException('readings는 배열이어야 한다');
  }

  return ExpertFile(
    poemId: poemId,
    badgePath: badgePath,
    readings: [
      for (final raw in rawReadings) _parseReading(raw),
    ],
  );
}

ExpertInterpretation _parseReading(Object? raw) {
  if (raw is! Map<String, Object?>) {
    throw const FormatException('readings의 항목은 객체여야 한다');
  }

  final rawClaims = raw['claims'];
  if (rawClaims is! List || rawClaims.isEmpty) {
    throw const FormatException('해석마다 claims가 하나 이상 있어야 한다');
  }

  return ExpertInterpretation(
    label: _requireText(raw, 'label'),
    stance: _requireText(raw, 'stance'),
    claims: [for (final claim in rawClaims) _parseClaim(claim)],
  );
}

Claim _parseClaim(Object? raw) {
  if (raw is! Map<String, Object?>) {
    throw const FormatException('claims의 항목은 객체여야 한다');
  }

  final rawLines = raw['lines'];
  if (rawLines is! List || rawLines.isEmpty) {
    throw const FormatException('주장마다 근거 행(lines)이 하나 이상 있어야 한다');
  }

  final lines = <int>[];
  for (final line in rawLines) {
    if (line is! int || line < 1) {
      throw const FormatException('근거 행 번호는 1부터 세는 정수여야 한다');
    }
    lines.add(line);
  }

  return Claim(lines: lines, point: _requireText(raw, 'point'));
}

String _requireText(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$key는 비어 있지 않은 문자열이어야 한다');
  }
  return value;
}

/// 에셋에서 시 한 편의 전문가 해석을 읽는다.
///
/// 파일이 없으면 null을 돌려준다. 아직 해석을 쓰지 않은 시가 있고, 그때
/// S07은 「전문가 해석 준비 중」을 보여야 하므로 없는 것은 오류가 아니다.
/// 파일이 있는데 형식이 어긋나면 [FormatException]이 그대로 올라간다 —
/// 조용히 빈 화면을 보여 주는 것보다 시연 전에 깨지는 쪽이 낫다.
Future<ExpertFile?> loadExpertFile(
  String poemId, {
  AssetBundle? bundle,
}) async {
  final source = await _tryLoadString(bundle ?? rootBundle, poemId);
  if (source == null) return null;
  return parseExpertFile(source);
}

Future<String?> _tryLoadString(AssetBundle bundle, String poemId) async {
  try {
    return await bundle.loadString(expertAssetPath(poemId));
  } on FlutterError {
    return null; // 에셋 목록에 없는 시
  }
}
