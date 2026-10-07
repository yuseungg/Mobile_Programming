// 주인: C · 용어: docs/여백-네이밍규칙.md 2장 「읽기 · 대화」

enum ChatRole { user, assistant }

class ChatMessage {
  const ChatMessage({required this.role, required this.text});

  final ChatRole role;
  final String text;

  bool get isUser => role == ChatRole.user;
}
