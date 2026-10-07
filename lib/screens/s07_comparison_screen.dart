import 'package:flutter/material.dart';
import '../core/data/mock_data.dart';
import '../core/theme/app_colors.dart';
import '../models/poem.dart';
import 's08_dialogue_list_screen.dart';

/// S07 대조 화면
/// - 최신 기획서 기준: 내 해석 ➔ 전문가 해석 A ➔ 전문가 해석 B
/// - 코드가 근거 행을 대조하여 관계를 판정
/// - 창작 배경 보기 (바텀시트) & 다른 사람의 대화 보기 (S08 이동)
class S07ComparisonScreen extends StatelessWidget {
  final Poem poem;
  final String myInterpretation;
  final List<int> myGroundedLines;

  const S07ComparisonScreen({
    super.key,
    required this.poem,
    required this.myInterpretation,
    required this.myGroundedLines,
  });

  /// 기본 생성자 (MockData 기본값 활용)
  factory S07ComparisonScreen.mock() {
    return S07ComparisonScreen(
      poem: MockData.seosi,
      myInterpretation: MockData.mySampleInterpretation,
      myGroundedLines: MockData.mySampleGroundedLines,
    );
  }

  void _showHistoricalContext(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                '창작 배경',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  fontFamily: 'NanumMyeongjo',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                poem.historicalContext,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.inputBackground,
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('닫기'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          '${poem.title} — 대조',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // B의 PoemView 도착 전 임시 시 정보 카드
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.menu_book_outlined, size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${poem.title} · ${poem.poet} (${poem.year})',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    '내 근거: ${myGroundedLines.map((e) => '$e행').join(', ')}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.confirmedGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 1. 내 해석 (가장 위, 가장 무겁게)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.userBubbleBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.accentWine.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.accentWine,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '내 해석',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '내가 직접 다듬어 저장한 생각',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    myInterpretation,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: AppColors.textPrimary,
                      fontFamily: 'NanumMyeongjo',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. 전문가 해석 목록 (코드가 관계 계산)
            ...poem.expertReadings.map((reading) {
              final relationship = reading.calculateRelationship(myGroundedLines);

              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 전문가 라벨 & 코드가 계산한 관계 한 줄
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          reading.label,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.confirmedGreen.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            relationship,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.confirmedGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // 입장 (stance)
                    Text(
                      reading.stance,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.infoBlue,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // 비교 문장 (AI 작성, 공통점 우선 서술)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.inputBackground,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        reading.comparisonSentence,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // 전문가 해석 본문
                    Text(
                      reading.fullText,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 12),

            // 하단 버튼 영역
            // (1) 창작 배경 보기 (바텀시트)
            OutlinedButton.icon(
              onPressed: () => _showHistoricalContext(context),
              icon: const Icon(Icons.history_edu_outlined, size: 18),
              label: const Text('창작 배경 보기'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // (2) 다른 사람의 대화 보기 (S08 이동)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => S08DialogueListScreen(
                      poemId: poem.id,
                      poemTitle: poem.title,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.people_outline, size: 18),
              label: const Text('다른 사람의 대화 보기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentWine,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
