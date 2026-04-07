import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/chat_message.dart';
import '../theme.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    switch (message.type) {
      case MessageType.system:
        return _SystemLine(message: message);
      case MessageType.user:
        return _BubbleRow(message: message, isOwn: true);
      case MessageType.incoming:
        return _BubbleRow(message: message, isOwn: false);
    }
  }
}

class _SystemLine extends StatelessWidget {
  final ChatMessage message;
  const _SystemLine({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Expanded(child: Divider(color: AppTheme.border, thickness: 0.5)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              message.text,
              style: GoogleFonts.ibmPlexMono(
                fontSize: 11,
                color: AppTheme.systemText,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const Expanded(child: Divider(color: AppTheme.border, thickness: 0.5)),
        ],
      ),
    );
  }
}

class _BubbleRow extends StatelessWidget {
  final ChatMessage message;
  final bool isOwn;

  const _BubbleRow({required this.message, required this.isOwn});

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm').format(message.timestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment:
            isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isOwn && message.sender != null)
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 3),
              child: Text(
                message.sender!,
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 11,
                  color: AppTheme.accent,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          Row(
            mainAxisAlignment:
                isOwn ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isOwn) _Avatar(sender: message.sender ?? '?'),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72,
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isOwn ? AppTheme.userBubble : AppTheme.surfaceAlt,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isOwn ? 16 : 4),
                      bottomRight: Radius.circular(isOwn ? 4 : 16),
                    ),
                    border: isOwn
                        ? Border.all(color: AppTheme.accentDim.withOpacity(0.3))
                        : Border.all(color: AppTheme.border),
                  ),
                  child: Text(
                    message.text,
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              if (isOwn) const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  time,
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 10,
                    color: AppTheme.systemText,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String sender;
  const _Avatar({required this.sender});

  Color _colorFor(String name) {
    const colors = [
      Color(0xFF00B89A),
      Color(0xFF5B8DD9),
      Color(0xFFD97B5B),
      Color(0xFF9B59B6),
      Color(0xFFE67E22),
    ];
    return colors[name.codeUnitAt(0) % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 14,
      backgroundColor: _colorFor(sender).withOpacity(0.2),
      child: Text(
        sender.isNotEmpty ? sender[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: _colorFor(sender),
        ),
      ),
    );
  }
}