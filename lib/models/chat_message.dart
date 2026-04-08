enum MessageType { user, system, incoming }

class ChatMessage {
  final String text;
  final MessageType type;
  final String? sender;

  ChatMessage({
    required this.text,
    required this.type,
    this.sender,
  });

  factory ChatMessage.fromServer(String raw) {
    raw = raw.trim();

    if (raw.startsWith('[SERVER]')) {
      return ChatMessage(
        text: raw.replaceFirst('[SERVER]', '').trim(),
        type: MessageType.system,
      );
    }

    final match = RegExp(r'^\[(.+?)\]: (.+)$').firstMatch(raw);
    if (match != null) {
      return ChatMessage(
        text: match.group(2)!,
        type: MessageType.incoming,
        sender: match.group(1),
      );
    }

    return ChatMessage(
      text: raw,
      type: MessageType.system,
    );
  }
}