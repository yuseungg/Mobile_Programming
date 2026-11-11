// S06 정리 · 저장 — 주인: B
// 저장 뒤 S07로 갈 땐 앞 화면 다 닫음 (대조 연 뒤엔 못 고쳐서 돌아오면 안 됨)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/router.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../data/fakes/fake_data.dart';
import '../../data/models/chat_message.dart';
import '../../data/models/reading.dart';
import '../../data/repositories.dart';

class SaveScreen extends StatefulWidget {
  const SaveScreen({super.key, required this.poemId});

  final String poemId;

  @override
  State<SaveScreen> createState() => _SaveScreenState();
}

class _SaveScreenState extends State<SaveScreen> {
  // S01이 아직 진짜 로그인을 안 시켜서 없으면 가짜 계정으로
  final String _userId = Repositories.auth.currentUserId ?? FakeData.myUserId;

  Reading? _reading;
  bool _isLocked = false; // 대조 연 뒤엔 해석 못 고침 (기획서 F4)
  bool _isPublic = false;
  bool _wasPublic = false; // 공개로 한 번 저장하면 못 되돌림
  bool _isSaving = false;
  final TextEditingController _interpretationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    Reading? reading = await Repositories.reading.fetchReading(_userId, widget.poemId);
    if (!mounted || reading == null) {
      return;
    }

    String text;
    if (reading.isSaved) {
      // 이미 저장한 해석 있으면 그거 보여줌
      text = reading.interpretation;
    } else {
      // 없으면 대화에서 내가 한 말만 모아서 초안
      List<String> myMessages = [];
      for (ChatMessage message in reading.conversation) {
        if (message.role == ChatRole.user) {
          myMessages.add(message.text);
        }
      }
      text = myMessages.join('\n');
    }

    setState(() {
      _reading = reading;
      _isLocked = reading.hasOpenedComparison;
      _isPublic = reading.isPublic;
      _wasPublic = reading.isSaved && reading.isPublic;
      _interpretationController.text = text;
    });
  }

  @override
  void dispose() {
    _interpretationController.dispose();
    super.dispose();
  }



  //AI
  // 해석 저장 = 잠금 해제. 뱃지랑 공개 대화도 저장소에서 같이 처리됨
  Future<void> _save() async {
    setState(() {
      _isSaving = true;
    });

    Reading base = _reading ?? Reading(poemId: widget.poemId);
    Reading toSave = base.copyWith(interpretation: _interpretationController.text.trim(), isPublic: _isPublic);

    // TODO: D 요약기(#8) 머지되면 그걸로 바꿔야 함. 지금은 내 해석을 그대로 요약 자리에 넣음
    // 비공개면 요약 안 씀 (#12 머지되면 '' 대신 null)
    String summary = '';
    if (_isPublic) {
      summary = toSave.interpretation;
    }

    try {
      await Repositories.reading.saveInterpretation(_userId, toSave, summary: summary);
    } on InterpretationLockedException {
      _showMessage(AppStrings.saveLockedNotice);
      return;
    } catch (e) {
      _showMessage(AppStrings.saveFailed);
      return;
    }

    if (!mounted) {
      return;
    }
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.comparison(widget.poemId),
      (route) => route.isFirst,
    );
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    setState(() {
      _isSaving = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final poem = FakeData.poemById(widget.poemId);
    List<int> evidenceLines = [];
    if (_reading != null) {
      evidenceLines = _reading!.evidenceLines;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.saveTitle),
        backgroundColor: AppColors.background,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            _isLocked ? AppStrings.saveLockedNotice : AppStrings.saveDraftNotice,
            style: const TextStyle(color: AppColors.textSub),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _interpretationController,
            readOnly: _isLocked,
            maxLength: 500,
            // 웹 기본값은 한글 조합 중엔 제한을 풀어서 500자 넘어감
            maxLengthEnforcement:MaxLengthEnforcement.enforced, //AI

            minLines: 6,
            maxLines: null,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(
              fontFamily: AppFonts.myeongjo,
              fontSize: 18,
              height: 1.7,
              color: AppColors.text,
            ),
            decoration: const InputDecoration(
              filled: true,
              fillColor: AppColors.card,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            AppStrings.saveEvidenceLabel,
            style: TextStyle(color: AppColors.textFaint),
          ),
          for (final lineNo in evidenceLines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(width: 20, height: 2, color: AppColors.confirmed),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      poem.lineAt(lineNo),
                      style: const TextStyle(
                        fontFamily: AppFonts.myeongjo,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text(AppStrings.savePublicLabel),
            subtitle: const Text(AppStrings.savePublicCaption),
            value: _isPublic,
            onChanged: (_isLocked || _wasPublic) ? null : (value) => setState(() => _isPublic = value),
          ),
        ],
      ),
      // 저장 버튼은 화면 아래 고정 (화면설계 PDF)
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton(
              // 잠금을 여는 버튼은 와인색 (화면설계 PDF)
              style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
              onPressed:
                  (_interpretationController.text.trim().isEmpty || _isSaving) ? null : _save,
              child: const Text(AppStrings.saveButton),
            ),
            const SizedBox(height: 8),
            const Text(
              AppStrings.saveLockNotice,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textFaint),
            ),
          ],
        ),
      ),
    );
  }
}
