// 주인: A — 대화 중단(Stop) 버튼 (기획서 7장)
// 화면이 cancel()을 부르면 진행 중인 요청을 끊고, 남은 툴 라운드도 부르지 않는다.

class CancelToken {
  bool _isCancelled = false;
  final _listeners = <void Function()>[];

  bool get isCancelled => _isCancelled;

  void cancel() {
    if (_isCancelled) return;
    _isCancelled = true;
    final listeners = List.of(_listeners);
    _listeners.clear();
    for (final listener in listeners) {
      listener();
    }
  }

  /// 취소되면 불릴 함수. 이미 취소됐으면 바로 부른다.
  void addListener(void Function() listener) {
    if (_isCancelled) {
      listener();
    } else {
      _listeners.add(listener);
    }
  }

  void removeListener(void Function() listener) => _listeners.remove(listener);
}
