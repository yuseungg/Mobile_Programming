// 주인: A — 공용 입력칸 (위에 라벨, 아래에 도움말·글자 수)
import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'char_counter.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hintText,
    this.helperText,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines = 1,
    this.minLines,
    this.counterMax,
    this.style = AppText.body,
    this.onChanged,
    this.below,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final String? helperText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int? maxLines;
  final int? minLines;

  /// 글자 수 표시 기준. 1단계에서는 표시만 하고 막지 않는다. controller가 있어야 보인다.
  final int? counterMax;
  final TextStyle style;
  final ValueChanged<String>? onChanged;

  /// 입력칸 바로 아래에 붙일 위젯 (예: 비밀번호 일치 여부)
  final Widget? below;

  @override
  Widget build(BuildContext context) {
    final labelText = label;
    final textController = controller;
    final max = counterMax;
    final belowWidget = below;
    // 한 줄 입력칸은 글자 수를 칸 안 오른쪽에, 여러 줄은 칸 아래 오른쪽에 둔다 (목업 기준).
    final isSingleLine = maxLines == 1 || obscureText;
    final showCounter = textController != null && max != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (labelText != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(labelText, style: AppText.label),
          ),
        TextField(
          controller: textController,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLines: obscureText ? 1 : maxLines,
          minLines: minLines,
          style: style,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            helperText: helperText,
            suffixIcon: showCounter && isSingleLine
                ? Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: CharCounter(controller: textController, max: max),
                  )
                : null,
            suffixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
          ),
        ),
        if (belowWidget != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: belowWidget,
          ),
        if (showCounter && !isSingleLine)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Align(
              alignment: Alignment.centerRight,
              child: CharCounter(controller: textController, max: max),
            ),
          ),
      ],
    );
  }
}
