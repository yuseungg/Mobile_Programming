// 주인: A — 말풍선
// 사용자 말은 명조(시의 편), AI 말은 고딕(앱의 편).
import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../data/models/chat_message.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message, this.isPending = false});

  final ChatMessage message;
  final bool isPending; // AI 응답을 기다리는 동안 보이는 자리 표시 말풍선

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    const corner = Radius.circular(16);
    const tail = Radius.circular(4);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isUser ? AppColors.accentBg : AppColors.card,
            border: isUser ? null : Border.all(color: AppColors.border),
            borderRadius: BorderRadius.only(
              topLeft: corner,
              topRight: corner,
              bottomLeft: isUser ? corner : tail,
              bottomRight: isUser ? tail : corner,
            ),
          ),
          child: Text(
            message.text,
            style: isPending
                ? AppText.caption
                : (isUser ? AppText.userMessage : AppText.aiMessage),
          ),
        ),
      ),
    );
  }
}
