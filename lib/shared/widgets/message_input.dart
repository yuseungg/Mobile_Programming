// 주인: A — 대화 입력창
// 1단계: 보내기 버튼은 아무 일도 하지 않는다. 200자 제한과 AI 응답 중 잠금은 2단계.
import 'package:flutter/material.dart';

import '../../app/strings.dart';
import '../../app/theme.dart';
import 'char_counter.dart';

class MessageInput extends StatelessWidget {
  const MessageInput({
    super.key,
    required this.controller,
    required this.onSend,
    this.enabled = true,
    this.maxLength = 200,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool enabled;
  final int maxLength;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            enabled: enabled,
            minLines: 1,
            maxLines: 4,
            style: AppText.body,
            decoration: InputDecoration(
              hintText: AppStrings.chatInputHint,
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 14),
                child: CharCounter(controller: controller, max: maxLength),
              ),
              suffixIconConstraints:
                  const BoxConstraints(minWidth: 0, minHeight: 0),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 52,
          child: FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(72, 52),
              padding: const EdgeInsets.symmetric(horizontal: 18),
            ),
            onPressed: enabled ? onSend : null,
            child: const Text(AppStrings.chatSendButton),
          ),
        ),
      ],
    );
  }
}
