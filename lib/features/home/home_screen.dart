// S03 홈 — 주인: B
import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../data/fakes/fake_data.dart';
import '../../data/models/poem.dart';
import '../../data/models/reading.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories.dart';
import '../../shared/widgets/language_toggle.dart';
import '../save/pending_saves.dart';


//AI
// 추가된 순서대로 하루에 한 편씩 돌아감 (기획서 9장 3번)
Poem todayPoem(List<Poem> poems, DateTime now) {
  // 1970년 1월 1일부터 오늘까지 며칠 지났는지
  DateTime today = DateTime.utc(now.year, now.month, now.day);
  int days = today.difference(DateTime.utc(1970, 1, 1)).inDays;

  int index = days % poems.length;
  return poems[index];
}



class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final String _userId = Repositories.userId;

  UserProfile? _me;
  Set<String> _readPoemIds = {};
  Map<String, Reading> _readings = {}; // 시 누를 때 이어 읽기 / 초기화 고를지 보려고
  // 대화하다 저장 안 하고 나간 시 (이어 읽기, 기획서 F2)
  List<Reading> _inProgress = [];
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _retryThenLoad();
  }

  // 홈 열릴 때 전에 저장 실패해서 기기에 보관해 둔 해석 있으면 먼저 다시 저장 (기획서 7장)
  Future<void> _retryThenLoad() async {
    int saved = 0;
    try {
      saved = await retryPendingSaves();
    } catch (e) {
      // 기기 저장소 못 쓰는 환경이면 그냥 넘어감
    }
    await _load();

    if (saved > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.homePendingSaved)));
    }
  }

  Future<void> _load() async {
    UserProfile me;
    List<Reading> readings;
    try {
      me = await Repositories.user.fetchProfile(_userId);
      readings = await Repositories.reading.fetchMyReadings(_userId);
    } catch (e) {
      // 시 목록은 기기에 있어서 그대로 보이고, 누적일수 자리에 안내 + 다시 시도
      if (mounted) {
        setState(() {
          _loadFailed = true;
        });
      }
      return;
    }

    Set<String> ids = {};
    Map<String, Reading> byPoem = {};
    List<Reading> inProgress = [];
    for (Reading reading in readings) {
      ids.add(reading.poemId);
      byPoem[reading.poemId] = reading;
      if (!reading.isSaved && reading.conversation.isNotEmpty) {
        inProgress.add(reading);
      }
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _loadFailed = false;
      _me = me;
      _readPoemIds = ids;
      _readings = byPoem;
      _inProgress = inProgress;
    });
  }

  // 읽기 화면에서 돌아오면 누적일수랑 읽음 표시 다시 불러옴
  // 대화했거나 저장한 시는 이어 읽을지 초기화할지 먼저 고르게 함 (11/25 회의)
  void openReading(String poemId) {
    Reading? reading = _readings[poemId];
    if (reading != null && (reading.conversation.isNotEmpty || reading.isSaved)) {
      _askContinueOrReset(poemId);
      return;
    }
    Navigator.of(context).pushNamed(AppRoutes.reading(poemId)).then((_) => _load());
  }

  Future<void> _askContinueOrReset(String poemId) async {
    bool? reset = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(FakeData.poemById(poemId).title, style: AppText.poemTitleSmall),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(AppStrings.homeContinueTitle),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(AppStrings.homeReset),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || reset == null) {
      return;
    }
    if (!reset) {
      // 이어 읽기는 S04 안 거치고 바로 대화로
      openChat(poemId);
      return;
    }
    if (await _confirmReset()) {
      await _reset(poemId);
    }
  }

  Future<bool> _confirmReset() async {
    bool? ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(AppStrings.homeResetMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppStrings.homeResetCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppStrings.homeReset),
          ),
        ],
      ),
    );
    return ok == true;
  }

  // 지우고 나면 대화가 비어서 S04에서 첫 낱말부터 다시 씀
  Future<void> _reset(String poemId) async {
    try {
      await Repositories.reading.resetReading(_userId, poemId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.homeResetFailed)));
      }
      return;
    }
    // 예전 해석을 기기에 보관해 둔 게 있으면 다음 재시도 때 지운 걸 되살리니까 같이 지움
    try {
      await removePendingSave(_userId, poemId);
    } catch (e) {
      // print(e);
    }
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushNamed(AppRoutes.reading(poemId)).then((_) => _load());
  }

  // 이어 읽기는 읽기 화면 거치지 않고 바로 대화로. S05가 저장된 대화 불러와서 이어 감
  void openChat(String poemId) {
    Navigator.of(context).pushNamed(AppRoutes.chat(poemId)).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final poem =  todayPoem(FakeData.poems, DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppStrings.appName),
        backgroundColor: AppColors.background,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: AppStrings.homeProfileTooltip,
            onPressed: () => Navigator.of(context)
                .pushNamed(AppRoutes.profile(_userId)),
          ),
          const LanguageToggle(),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (_loadFailed)
            Row(
              children: [
                Expanded(child: Text(AppStrings.noticeUnavailable, style: AppText.bodySub)),
                TextButton(onPressed: _load, child: Text(AppStrings.noticeUnavailableAction)),
              ],
            )
          else
          Text(
            _me == null ? '' : AppStrings.homeTotalDays(_me!.totalReadingDays),
            style: AppText.bodySub,
          ),
          const SizedBox(height: 24),
          Text(
            AppStrings.homeTodayPoem,
            style: AppText.label,
          ),
          const SizedBox(height: 8),
          Card(
            color: AppColors.card,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    poem.title,
                    style: AppText.poemTitle,
                  ),
                  Text(
                    poem.author,
                    style:  AppText.bodySub,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    poem.lines.take(2).join('\n'),
                    style: AppText.poemQuote,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => openReading(poem.poemId),
                      child: Text(AppStrings.homeStartReading),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          if (_inProgress.isNotEmpty) ...[
            Text(AppStrings.homeContinueTitle, style: AppText.label),
            for (Reading reading in _inProgress)
              ListTile(
                title: Text(FakeData.poemById(reading.poemId).title, style: AppText.poemTitleSmall),
                subtitle: Text(AppStrings.homeContinueSubtitle(reading.firstWord)),
                trailing: const Icon(Icons.chat_bubble_outline),
                onTap: () => openChat(reading.poemId),
              ),
            const SizedBox(height: 24),
          ],
          Text(
            AppStrings.homePoemList,
            style: AppText.label,
          ),


          for (final p in FakeData.poems) //AI
            ListTile(
              title: Text(p.title, style: AppText.poemTitleSmall),
              subtitle: Text(p.author),
              trailing: _readPoemIds.contains(p.poemId)
                    ? Text(AppStrings.homeReadMark, style: AppText.caption)
                    : const Icon(Icons.chevron_right),
                onTap: () => openReading(p.poemId)
            ),
        ],
      ),
    );
  }
}
