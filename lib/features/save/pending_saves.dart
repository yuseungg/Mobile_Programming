// S06 저장 실패 대비 — 주인: B (기획서 7장 「오프라인 · 실패 처리」)
// 네트워크 같은 걸로 저장이 실패하면 기기에 보관했다가 다음에 홈 열릴 때 다시 저장함.
// 저장은 잠금 해제 · 뱃지 받는 곳이라 날아가면 안 됨
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../data/firestore/converters.dart';
import '../../data/models/reading.dart';
import '../../data/repositories.dart';

const String _key = 'pendingSaves';



// 보관된 거 전부 읽기. 값이 깨져 있으면 그냥 빈 걸로
List<Map<String, dynamic>> _readAll(SharedPreferences prefs) {
  String? raw = prefs.getString(_key);
  List<Map<String, dynamic>> result = [];
  if (raw == null) {
    return result;
  }
  try {
    List<dynamic> items = jsonDecode(raw) as List<dynamic>;
    for (dynamic item in items) {
      result.add(Map<String, dynamic>.from(item as Map));
    }
  } catch (e) {
    return [];
  }
  return result;
}

bool _isSame(Map<String, dynamic> item, String userId, String poemId) {
  return item['userId'] == userId && item['poemId'] == poemId;
}


//AI
// 실패한 저장 보관. 같은 시는 하나만 (또 실패하면 최신 걸로 덮음)
Future<void> keepPendingSave(String userId, Reading reading, String? summary) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  List<Map<String, dynamic>> next = [];
  for (Map<String, dynamic> item in _readAll(prefs)) {
    if (!_isSame(item, userId, reading.poemId)) {
      next.add(item);
    }
  }
  next.add({
    'userId': userId,
    'poemId': reading.poemId,
    'reading': readingToDoc(reading),
    'summary': summary,
  });
  await prefs.setString(_key, jsonEncode(next));
}

// 저장 성공하면 그 시 보관분은 지움 (나중에 옛날 해석으로 덮어쓰지 않게)
Future<void> removePendingSave(String userId, String poemId) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  List<Map<String, dynamic>> next = [];
  for (Map<String, dynamic> item in _readAll(prefs)) {
    if (!_isSame(item, userId, poemId)) {
      next.add(item);
    }
  }
  await prefs.setString(_key, jsonEncode(next));
}

// S06 다시 열었을 때 보관해 둔 해석 있으면 그걸 보여주려고
Future<Reading?> findPendingSave(String userId, String poemId) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  for (Map<String, dynamic> item in _readAll(prefs)) {
    if (_isSame(item, userId, poemId)) {
      return readingFromDoc(poemId, Map<String, dynamic>.from(item['reading'] as Map)); //AI
    }
  }
  return null;
}



//AI
// 보관된 거 다시 저장. 성공한 건 지우고 또 실패한 건 남겨둠. 저장된 개수 돌려줌
// 대조 연 뒤라 막힌 거나 요약 없는 공개 저장은 다시 해도 안 되니까 버림
Future<int> retryPendingSaves() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  List<Map<String, dynamic>> items = _readAll(prefs);
  if (items.isEmpty) {
    return 0;
  }

  List<Map<String, dynamic>> left = [];
  int saved = 0;
  for (Map<String, dynamic> item in items) {
    String userId = item['userId'] as String;
    String poemId = item['poemId'] as String;
    Reading reading = readingFromDoc(poemId, Map<String, dynamic>.from(item['reading'] as Map));
    String? summary = item['summary'] as String?;
    try {
      await Repositories.reading.saveInterpretation(userId, reading, summary: summary);
      saved++;
    } on InterpretationLockedException {
      // 버림
    } on ArgumentError {
      // 버림
    } catch (e) {
      left.add(item);
    }
  }
  await prefs.setString(_key, jsonEncode(left));
  return saved;
}
