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

// 보관분 두 개가 같은 내용인지. 재시도가 끝난 뒤에 지워도 되는 것만 지우려고 쓴다.
// jsonEncode로 비교하면 키 순서에 기대게 되므로 직접 훑는다.
bool _isSameContent(Object? a, Object? b) {
  if (a is Map && b is Map) {
    if (a.length != b.length) {
      return false;
    }
    for (Object? key in a.keys) {
      if (!b.containsKey(key) || !_isSameContent(a[key], b[key])) {
        return false;
      }
    }
    return true;
  }
  if (a is List && b is List) {
    if (a.length != b.length) {
      return false;
    }
    for (int i = 0; i < a.length; i++) {
      if (!_isSameContent(a[i], b[i])) {
        return false;
      }
    }
    return true;
  }
  return a == b;
}

bool _isStillKept(SharedPreferences prefs, Map<String, dynamic> item) {
  for (Map<String, dynamic> now in _readAll(prefs)) {
    if (_isSameContent(now, item)) {
      return true;
    }
  }
  return false;
}


//AI
// 보관분의 요약 두 벌. 비공개로 보관했으면 null
// 예전 버전은 요약을 'summary' 하나로 보관했음 — 그런 보관분은 그걸 두 언어에 같이 씀
// (안 그러면 공개 저장인데 요약이 없다고 버려져서 저장이 날아감)
({String ko, String en})? _summaryOf(Map<String, dynamic> item) {
  String? old = item['summary'] as String?;
  String? ko = item['summaryKo'] as String? ?? old;
  String? en = item['summaryEn'] as String? ?? old;
  if (ko == null || en == null) {
    return null;
  }
  return (ko: ko, en: en);
}

// 실패한 저장 보관. 같은 시는 하나만 (또 실패하면 최신 걸로 덮음)
// 요약은 한국어 · 영어 두 벌을 같이 보관 (비공개면 null)
Future<void> keepPendingSave(String userId, Reading reading, ({String ko, String en})? summary) async {
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
    'summaryKo': summary?.ko,
    'summaryEn': summary?.en,
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
//
// 끝낸 것만 기기 저장소에서 뺀다. 시작할 때 읽은 목록으로 통째로 덮어쓰면,
// 재시도가 네트워크를 기다리는 사이에 S06에서 보관한 해석이 사라진다
// (홈이 initState에서 이 함수를 띄워 두므로 그 사이에 S06까지 갈 수 있다).
Future<int> retryPendingSaves() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  List<Map<String, dynamic>> items = _readAll(prefs);
  if (items.isEmpty) {
    return 0;
  }

  // 다시 저장했거나 버린 것들. 내용을 그대로 들고 있다가 마지막에 대조한다 —
  // 그 사이에 같은 시를 또 보관했으면 내용이 달라지고, 그 새 보관분은 지우지 않는다.
  List<Map<String, dynamic>> done = [];
  int saved = 0;
  // 지금 로그인한 사람 것만 다시 저장 (C — 로그인 분기). 다른 계정 것은 그 사람이 로그인할 때까지 둠
  String? me = Repositories.auth.currentUserId;
  for (Map<String, dynamic> item in items) {
    String userId = item['userId'] as String;
    if (userId != me) {
      continue;
    }
    String poemId = item['poemId'] as String;
    Reading reading = readingFromDoc(poemId, Map<String, dynamic>.from(item['reading'] as Map));
    ({String ko, String en})? summary = _summaryOf(item);
    try {
      // 최신 기록 바탕으로 하고 해석 · 공개 · 근거 행만 보관분에서 가져옴
      // (보관한 뒤에 S04에서 멈춘 행 바꿨거나 설정에서 대화 지웠으면 지금 값이 맞음)
      Reading? now = await Repositories.reading.fetchReading(userId, poemId);
      if (now != null) {
        reading = now.copyWith(interpretation: reading.interpretation,
            isPublic: reading.isPublic, evidenceLines: reading.evidenceLines);
      }
      // 기다리는 사이 S06에서 새로 저장됐거나(보관분 지워짐) 또 보관했으면(내용 바뀜)
      // 이건 옛 해석이라 건너뜀. 안 그러면 새 해석을 옛 해석으로 덮어씀
      if (!_isStillKept(prefs, item)) {
        continue;
      }
      await Repositories.reading.saveInterpretation(userId, reading, summary: summary);
      saved++;
      done.add(item);
    } on InterpretationLockedException {
      done.add(item); // 버림
    } on ArgumentError {
      done.add(item); // 버림
    } catch (e) {
      // 남겨 둔다 (다음에 홈 열릴 때 또 해 봄)
    }
  }

  // 지금 목록을 다시 읽어서 끝낸 것만 뺀다. 재시도가 도는 사이에 들어온 보관분은
  // done에 없으므로 그대로 남는다.
  List<Map<String, dynamic>> left = [];
  for (Map<String, dynamic> item in _readAll(prefs)) {
    bool isDone = false;
    for (Map<String, dynamic> finished in done) {
      if (_isSameContent(item, finished)) {
        isDone = true;
        break;
      }
    }
    if (!isDone) {
      left.add(item);
    }
  }
  await prefs.setString(_key, jsonEncode(left));
  return saved;
}
