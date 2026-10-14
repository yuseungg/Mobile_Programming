// 주인: A — 대화 입력창
// 한 번에 최대 200자 (기획서 5장 입력 제약) — 넘게는 입력되지 않는다.
// AI가 답하는 동안은 입력할 수 없고, 보내기 자리에 중단 버튼이 나온다 (기획서 7장).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/strings.dart';
import '../../app/theme.dart';
import 'char_counter.dart';

class MessageInput extends StatelessWidget {
  const MessageInput({
    super.key,
    required this.controller,
    required this.onSend,
    this.onStop,
    this.isResponding = false,
    this.maxLength = 200,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback? onStop; // 응답을 기다리는 동안 누르는 중단 버튼
  final bool isResponding;
  final int maxLength;

  @override
  Widget build(BuildContext context) {
    const buttonSize = Size(72, 52);
    const buttonPadding = EdgeInsets.symmetric(horizontal: 18);

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            enabled: !isResponding,
            minLines: 1,
            maxLines: 4,
            style: AppText.body,
            inputFormatters: [LengthLimitingTextInputFormatter(maxLength)],
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
          child: isResponding
              ? OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: buttonSize,
                    padding: buttonPadding,
                  ),
                  onPressed: onStop,
                  child: const Text(AppStrings.chatStopButton),
                )
              : ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (context, value, _) => FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: buttonSize,
                      padding: buttonPadding,
                    ),
                    onPressed: value.text.trim().isEmpty ? null : onSend,
                    child: const Text(AppStrings.chatSendButton),
                  ),
                ),
        ),
      ],
    );
  }
}
