/// 시를 끝까지 읽고 최종 저장했을 때 획득하는 뱃지 모델
class PoemBadge {
  final String id;
  final String poemId;
  final String name; // 예: '별', '꽃', '고양이'
  final String poemTitle;
  final String iconSymbol; // 에셋 이미지 대체용 유니코드/심볼 또는 경로
  final DateTime? acquiredDate;

  const PoemBadge({
    required this.id,
    required this.poemId,
    required this.name,
    required this.poemTitle,
    required this.iconSymbol,
    this.acquiredDate,
  });

  bool get isAcquired => acquiredDate != null;
}
