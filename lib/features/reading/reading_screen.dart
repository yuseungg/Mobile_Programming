// S04 읽기 — 주인: B
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/router.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../data/fakes/fake_data.dart';
import '../../data/models/reading.dart';
import '../../data/repositories.dart';
import '../../shared/widgets/language_toggle.dart';
import '../../shared/widgets/poem_view.dart';

class ReadingScreen extends StatefulWidget {
  const ReadingScreen({super.key, required this.poemId});

  final String poemId;

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  final String _userId = Repositories.userId;

  final Set<int> _markedLines = {};
  final Set<int> _savingLines = {}; // 저장 중인 행 (그동안 또 누르면 무시)
  Map<int, int> _stopCounts = {};
  bool _hasConversation = false; // 하던 대화 있으면 버튼을 '대화 이어 하기'로
  bool _isSavingWord = false; // 첫 낱말 저장 중엔 버튼 막음 (두 번 눌러서 S05 두 번 열리는 거 방지)
  bool _loadFailed = false; // 기록 못 불러왔으면 안내 + 버튼 막음
  final TextEditingController _firstWordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _countReadingDay();
    _load();
  }

  // 들어올 때 누적일수 셈 (한국 시간 기준 하루 한 번, 저장소에서 처리)
  // 네트워크 문제로 못 세도 읽기는 그냥 되게 함
  Future<void> _countReadingDay() async {
    try {
      await Repositories.user.countReadingDay(_userId);
    } catch (e) {
      // print(e);
    }
  }

  Future<void> _load() async {
    // 전에 읽던 시면 멈춘 행이랑 첫 낱말 그대로 불러옴
    Reading? saved;
    Map<int, int> counts;
    try {
      saved = await Repositories.reading.fetchReading(_userId, widget.poemId);
      counts = await Repositories.reading.fetchStopCounts(widget.poemId);
    } catch (e) {
      // 오프라인에서 처음 여는 시는 여기서 실패함. 그냥 두면 빈 화면이라
      // 하던 대화가 있어도 첫 낱말을 새로 쓰게 됨 → 불러올 때까지 버튼 막음
      if (mounted) {
        setState(() {
          _loadFailed = true;
        });
      }
      return;
    }
    // print(counts);

    if (!mounted) {
      return;
    }
    setState(() {
      _loadFailed = false;
      if (saved != null) {
        _markedLines.addAll(saved.markedLines);
        _firstWordController.text = saved.firstWord;
        _hasConversation = saved.conversation.isNotEmpty;
      }
      _stopCounts = counts;
    });
  }



  //AI
  // 누르면 내 멈춘 행이랑 집계가 같이 바뀜. 집계엔 나도 들어가 있어서 다시 받아옴
  // 화면 먼저 바꾸고, 저장 실패하면 되돌림 (화면이랑 서버가 어긋나면 안 됨)
  Future<void> _toggleLine(int lineNo) async {
    if (_savingLines.contains(lineNo)) {
      return;
    }
    bool isMarked = !_markedLines.contains(lineNo);
    _savingLines.add(lineNo);
    setState(() {
      _setMarked(lineNo, isMarked);
    });

    try {
      await Repositories.reading.setMarkedLine(_userId, widget.poemId, lineNo, isMarked: isMarked);
    } catch (e) {
      _savingLines.remove(lineNo);
      if (!mounted) {
        return;
      }
      setState(() {
        _setMarked(lineNo, !isMarked);
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.readingMarkFailed)));
      return;
    }
    _savingLines.remove(lineNo);


    // 집계 못 받아오면 원래 숫자 그대로 둠 (멈춘 건 이미 저장됨)
    Map<int, int> counts = _stopCounts;
    try {
      counts = await Repositories.reading.fetchStopCounts(widget.poemId);
    } catch (e) {
      // print(e);
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _stopCounts = counts;
    });
  }

  void _setMarked(int lineNo, bool isMarked) {
    if (isMarked) {
      _markedLines.add(lineNo);
    } else {
      _markedLines.remove(lineNo);
    }
  }

  // 첫 낱말 저장. S05가 저장소에서 이걸 꺼내 씀
  // 못 하면 안내만 띄우고 안 넘어감 (넘어가면 S05가 낱말 없이 시작함)
  Future<bool> _saveFirstWord() async {
    setState(() {
      _isSavingWord = true;
    });
    try {
      Reading? latest = await Repositories.reading.fetchReading(_userId, widget.poemId);
      latest ??= Reading(poemId: widget.poemId);
      await Repositories.reading.saveProgress(_userId, latest.copyWith(firstWord: _firstWordController.text.trim()));
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.saveFailed)));
      }
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _isSavingWord = false;
        });
      }
    }
  }

  Future<void> _startChat() async {
    bool saved = await _saveFirstWord();
    if (!saved || !mounted) {
      return;
    }
    await Navigator.of(context).pushNamed(AppRoutes.chat(widget.poemId));
    // 이 낱말로 대화 시작했으니 돌아오면 바로 잠금
    // (다시 불러오면 S05가 첫 질문 저장하기 전에 읽어서 안 잠길 수 있음)
    if (mounted) {
      setState(() {
        _hasConversation = true;
      });
    }
  }

  Future<void> _endWithWord() async {
    bool saved = await _saveFirstWord();
    if (!saved || !mounted) {
      return;
    }
    AppRouter.goToTab(context, AppRoutes.home);
  }

  @override
  void dispose() {
    _firstWordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final poem = FakeData.poemById(widget.poemId);
    // 낱말은 필수. 입력해야 두 버튼이 켜짐
    final hasFirstWord = _firstWordController.text.trim().isNotEmpty;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppStrings.readingAppBarTitle(poem.author, poem.title),
          style: AppText.bodySub,
        ),
        backgroundColor: AppColors.background,
        actions: const [LanguageToggle()],
      ),
      // 폰 내비게이션 바에 맨 아래 버튼 가려져서
      body: SafeArea(
        child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            poem.title,
            style: AppText.poemTitle,
          ),
          Text(
            AppStrings.readingAuthorYear(poem.author, poem.year),
            style:AppText.bodySub,
          ),
          if (_loadFailed)
            Row(
              children: [
                Expanded(child: Text(AppStrings.noticeUnavailable, style: AppText.bodySub)),
                TextButton(onPressed: _load, child: Text(AppStrings.noticeUnavailableAction)),
              ],
            ),
          const SizedBox(height: 24),
          PoemView(
            poem: poem,
            markedLines: _markedLines,
            stopCounts: _stopCounts,
            onLineTap: _toggleLine,
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.readingStopGuide,
            style: AppText.bodySub, // caption은 작고 흐려서 잘 안 보임
          ),
          const SizedBox(height: 32),
          Text(
            AppStrings.readingFirstWordLabel,
            style: AppText.label,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _firstWordController,
            maxLength: 20,
            //웹 기본값은 한글 조합 중엔 제한을 풀어서 20자 넘어감
              maxLengthEnforcement:  MaxLengthEnforcement.enforced,//AI
            onChanged: (_) => setState(() {}),
            // 대화 시작한 낱말은 못 바꿈. 바꾸면 S05는 예전 낱말로 한 대화를 이어 가고
            // 저장된 첫 낱말만 바뀌어서 S09에서 둘이 안 맞음
            readOnly: _hasConversation,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.input,
              border: const OutlineInputBorder(),
              helperText: _hasConversation ? AppStrings.readingFirstWordFixed : null,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: (!hasFirstWord || _isSavingWord || _loadFailed) ? null : _startChat,
            child: Text(_hasConversation ? AppStrings.readingContinueChat : AppStrings.readingStartChat),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: (!hasFirstWord || _isSavingWord || _loadFailed) ? null : _endWithWord,
            child: Text(AppStrings.readingEndWithWord),
          ),
        ],
      ),
      ),
    );
  }
}
