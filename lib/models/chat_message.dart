enum MessageType { user, system, incoming }

class ChatMessage {
  final String text;
  final MessageType type;
  final DateTime timestamp;
  final String? sender; // non-null for incoming messages

  const ChatMessage({
    required this.text,
    required this.type,
    required this.timestamp,
    this.sender,
  });

  /// Parse raw server text like "[Alice]: hello" or "[SERVER] Alice joined"
  factory ChatMessage.fromServer(String raw) {
    final now = DateTime.now();

    if (raw.startsWith('[SERVER]')) {
      return ChatMessage(
        text: raw.replaceFirst('[SERVER]', '').trim(),
        type: MessageType.system,
        timestamp: now,
      );
    }

    // Pattern: [username]: message
    final match = RegExp(r'^\[(.+?)\]: (.+)$').firstMatch(raw);
    if (match != null) {
      return ChatMessage(
        text: match.group(2)!,
        type: MessageType.incoming,
        timestamp: now,
        sender: match.group(1),
      );
    }

    return ChatMessage(
      text: raw,
      type: MessageType.system,
      timestamp: now,
    );
  }

  factory ChatMessage.own(String text) => ChatMessage(
        text: text,
        type: MessageType.user,
        timestamp: DateTime.now(),
      );
}