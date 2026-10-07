import 'package:flutter/material.dart';
import 'core/theme/app_colors.dart';
import 'screens/s07_comparison_screen.dart';
import 'screens/s08_dialogue_list_screen.dart';
import 'screens/s12_profile_screen.dart';

void main() {
  runApp(const YeobaekApp());
}

class YeobaekApp extends StatelessWidget {
  const YeobaekApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '여백',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accentWine,
          surface: AppColors.card,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
        ),
      ),
      home: const PartDTestHubScreen(),
    );
  }
}

/// 담당 D 화면 검증용 허브 (C의 전체 라우터 완성 전 임시 진입점)
class PartDTestHubScreen extends StatelessWidget {
  const PartDTestHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          '여백 — 담당 D 화면 테스트',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '담당 D (대조 · 커뮤니티 · 프로필)',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentWine,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '• 첫날 공용 산출물: MockData (서시, 전문가 해석 2개, 커뮤니티 글 3개)\n'
                    '• 화면: S07(대조), S08(대화 목록), S09(대화 보기), S12(프로필)',
                    style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildNavButton(
              context,
              title: 'S07. 전문가 해석 대조',
              subtitle: '내 해석 ➔ 전문가 A/B ➔ 창작배경 시트 ➔ S08 이동',
              icon: Icons.compare_arrows,
              destination: S07ComparisonScreen.mock(),
            ),
            const SizedBox(height: 12),
            _buildNavButton(
              context,
              title: 'S08. 모두의 대화 목록',
              subtitle: '서시 공개 대화 카드 목록 ➔ S09 이동',
              icon: Icons.forum_outlined,
              destination: const S08DialogueListScreen(),
            ),
            const SizedBox(height: 12),
            _buildNavButton(
              context,
              title: 'S12. 내 프로필 (내 선반)',
              subtitle: '닉네임, 누적일수, 모은 시 뱃지 선반',
              icon: Icons.person_outline,
              destination: S12ProfileScreen.myProfile(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget destination,
  }) {
    return Card(
      color: AppColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppColors.userBubbleBackground,
          child: Icon(icon, color: AppColors.accentWine, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => destination),
          );
        },
      ),
    );
  }
}
