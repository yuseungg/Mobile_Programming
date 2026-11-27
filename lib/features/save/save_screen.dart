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
import '../../writers/fake_summary_writer.dart';
import '../../writers/openrouter_summary_writer.dart';
import '../../writers/summary_writer.dart';
import '../../shared/widgets/language_toggle.dart';
import 'pending_saves.dart';

class SaveScreen extends StatefulWidget {
  const SaveScreen({super.key, required this.poemId, this.summaryWriter});

  final String poemId;
  // 공개 저장할 때 요약 쓰는 거 (D 담당). 비워 두면 키가 있을 때 모델이 쓰고,
  // 없거나 실패하면 사실 문장으로 채움 (createSummaryWriter)
  final SummaryWriter? summaryWriter;

  @override
  State<SaveScreen> createState() => _SaveScreenState();
}

class _SaveScreenState extends State<SaveScreen> {
  final String _userId = Repositories.userId;

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
    Reading? reading;
    try {
      reading = await Repositories.reading.fetchReading(_userId, widget.poemId);
    } catch (e) {
      // 못 불러와도 기기에 보관해 둔 게 있으면 그걸로 보여줌
    }
    Reading? pending = await _findPending();
    if (!mounted) {
      return;
    }
    if (reading == null && pending == null) {
      return;
    }
    Reading loaded = reading ?? pending!;

    String text;
    if (pending != null) {
      // 저장 실패해서 보관해 둔 해석이 제일 최신
      text = pending.interpretation;
    } else if (loaded.isSaved && loaded.interpretation.isNotEmpty) {
      // 이미 저장한 해석 있으면 그거 보여줌
      // (홈에서 초기화한 시는 저장은 돼 있어도 해석이 비어서 아래로 감)
      text = loaded.interpretation;
    } else {
      // 없으면 대화에서 내가 한 말만 모아서 초안
      List<String> myMessages = [];
      for (ChatMessage message in loaded.conversation) {
        if (message.role == ChatRole.user) {
          myMessages.add(message.text);
        }
      }
      text = myMessages.join('\n');
    }

    setState(() {
      _reading = loaded;
      _isLocked = loaded.hasOpenedComparison;
      _isPublic = pending != null ? pending.isPublic : loaded.isPublic;
      _wasPublic = loaded.isSaved && loaded.isPublic;
      _interpretationController.text = text;
    });
  }

  // 기기 저장소를 못 쓰는 환경이면 그냥 없는 걸로
  Future<Reading?> _findPending() async {
    try {
      return await findPendingSave(_userId, widget.poemId);
    } catch (e) {
      return null;
    }
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

    // 공개일 때만 D 요약기로 요약 만듦 (실패해도 예외 안 던지고 대신 문장 줌)
    // 비공개면 요약 안 씀
    String? summary;
    if (_isPublic) {
      SummaryRequest request = SummaryRequest(poemId: widget.poemId, firstWord: toSave.firstWord,
          conversation: toSave.conversation, interpretation: toSave.interpretation);
      // 요약기는 원래 안 던지지만 혹시 새면 _isSaving이 안 풀려서 화면이 통째로 잠김
      // 요약 때문에 저장 못 하면 안 되니까 사실 문장으로 대신함
      SummaryText result;
      try {
        SummaryWriter writer =
            widget.summaryWriter ?? await createSummaryWriter();
        result = await writer.write(request);
      } catch (e) {
        result = await const FakeSummaryWriter().write(request);
      }
      summary = result.text;
    }

    try {
      await Repositories.reading.saveInterpretation(_userId, toSave, summary: summary);
    } on InterpretationLockedException {
      _showMessage(AppStrings.saveLockedNotice);
      return;
    } catch (e) {
      // 네트워크 같은 문제면 기기에 보관해 두고 다음에 홈 열릴 때 다시 저장
      try {
        await keepPendingSave(_userId, toSave, summary);
        _showMessage(AppStrings.saveKeptForLater);
      } catch (e2) {
        _showMessage(AppStrings.saveFailed);
      }
      return;
    }

    // 저장됐으니 예전에 보관해 둔 게 있으면 지움 (나중에 옛날 해석으로 덮어쓰지 않게)
    try {
      await removePendingSave(_userId, widget.poemId);
    } catch (e) {
      // print(e);
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
        title: Text(AppStrings.saveTitle),
        backgroundColor: AppColors.background,
        actions: const [LanguageToggle()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            _isLocked ? AppStrings.saveLockedNotice : AppStrings.saveDraftNotice,
            style: AppText.bodySub,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _interpretationController,
            readOnly: _isLocked || _isSaving,
            maxLength: 500,
            // 웹 기본값은 한글 조합 중엔 제한을 풀어서 500자 넘어감
            maxLengthEnforcement:MaxLengthEnforcement.enforced, //AI

            minLines: 6,
            maxLines: null,
            onChanged: (_) => setState(() {}),
            style: AppText.interpretationLarge,
            decoration: const InputDecoration(
              filled: true,
              fillColor: AppColors.card,
              border: OutlineInputBorder(),
            ),
          ),
          // 근거 행 없으면 제목이랑 위 여백까지 통째로 숨김 (제목만 덩그러니 남았음)
          if (evidenceLines.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              AppStrings.saveEvidenceLabel,
              style: AppText.label,
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
                        style: AppText.poemQuote,
                      ),
                    ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 16),
          // 대조 연 뒤라도 비공개였으면 공개로 바꿀 수 있음 (해석은 못 고치니까 그대로 다시 저장됨)
          // 공개는 못 되돌림. 스위치 색이 그대로라 안 눌리는 걸로 보여서 이유 적어 둠
          SwitchListTile(
            title: Text(AppStrings.savePublicLabel),
            subtitle: Text(_wasPublic ? AppStrings.savePublicFixed : AppStrings.savePublicCaption),
            value: _isPublic,
            // 저장 중에 바꾸면 화면만 바뀌고 저장되는 값은 그대로라 막음 (공개 저장은 요약 쓰느라 오래 걸림)
            onChanged: (_wasPublic || _isSaving) ? null : (value) => setState(() => _isPublic = value),
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
              child: Text(AppStrings.saveButton),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.saveLockNotice,
              textAlign: TextAlign.center,
              style: AppText.caption,
            ),
          ],
        ),
      ),
    );
  }
}
