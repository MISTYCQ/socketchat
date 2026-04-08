import 'package:flutter/material.dart';
import '../services/enhanced_socket_service.dart';
import '../services/storage_service.dart';
import '../models/user.dart';
import '../theme.dart';
import 'private_chat_screen.dart';

/// ContactsScreen - Shows list of available users to chat with
/// 
/// Features:
/// - Displays online users from server
/// - Shows saved contacts
/// - Recent chat partners
/// - Click to start private chat
class ContactsScreen extends StatefulWidget {
  final EnhancedSocketService service;
  final String username;

  const ContactsScreen({
    super.key,
    required this.service,
    required this.username,
  });

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  List<String> _onlineUsers = [];
  List<String> _savedContacts = [];
  List<String> _recentUsers = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    _listenToUserList();
  }

  Future<void> _loadData() async {
    final contacts = await StorageService.getSavedContacts();
    final recent = await StorageService.getRecentUsers();
    
    setState(() {
      _savedContacts = contacts;
      _recentUsers = recent;
    });
  }

  void _listenToUserList() {
    widget.service.userList.listen((users) {
      setState(() {
        _onlineUsers = users.where((u) => u != widget.username).toList();
      });
    });
  }

  void _openChat(String contactUsername) {
    // Save contact
    StorageService.saveContact(contactUsername);
    
    // Navigate to private chat
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrivateChatScreen(
          service: widget.service,
          currentUsername: widget.username,
          contactUsername: contactUsername,
        ),
      ),
    );
  }

  void _logout() {
    widget.service.disconnect();
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chats',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              'Logged in as ${widget.username}',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.accent),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            // Online Users Section
            if (_onlineUsers.isNotEmpty) ...[
              _buildSectionHeader('Online Now', _onlineUsers.length),
              ..._onlineUsers.map((user) => _buildUserTile(
                    user,
                    isOnline: true,
                    subtitle: 'Online',
                  )),
              const SizedBox(height: 16),
            ],

            // Saved Contacts Section
            if (_savedContacts.isNotEmpty) ...[
              _buildSectionHeader('Saved Contacts', _savedContacts.length),
              ..._savedContacts
                  .where((u) => !_onlineUsers.contains(u) && u != widget.username)
                  .map((user) => _buildUserTile(
                        user,
                        isOnline: false,
                        subtitle: 'Offline',
                      )),
              const SizedBox(height: 16),
            ],

            // Recent Chats Section
            if (_recentUsers.isNotEmpty) ...[
              _buildSectionHeader('Recent', _recentUsers.length),
              ..._recentUsers
                  .where((u) =>
                      !_onlineUsers.contains(u) &&
                      !_savedContacts.contains(u) &&
                      u != widget.username)
                  .map((user) => _buildUserTile(
                        user,
                        isOnline: false,
                        subtitle: 'Recently used',
                      )),
            ],

            // Empty State
            if (_onlineUsers.isEmpty &&
                _savedContacts.isEmpty &&
                _recentUsers.isEmpty)
              _buildEmptyState(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddContactDialog,
        backgroundColor: AppTheme.accent,
        foregroundColor: AppTheme.bg,
        icon: const Icon(Icons.person_add),
        label: const Text('New Chat'),
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(
    String username, {
    required bool isOnline,
    required String subtitle,
  }) {
    final initial = username.isNotEmpty ? username[0].toUpperCase() : '?';
    final avatarColor = _getColorForUsername(username);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: avatarColor.withOpacity(0.2),
              child: Text(
                initial,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: avatarColor,
                ),
              ),
            ),
            if (isOnline)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.surface, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          username,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: isOnline ? Colors.green : AppTheme.textSecondary,
          ),
        ),
        trailing: Icon(
          Icons.chat_bubble_outline,
          color: AppTheme.accent.withOpacity(0.6),
        ),
        onTap: () => _openChat(username),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: AppTheme.systemText.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'No contacts yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to start a new chat',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddContactDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text(
          'Start New Chat',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Enter username',
            hintStyle: const TextStyle(color: AppTheme.textSecondary),
            filled: true,
            fillColor: AppTheme.surfaceAlt,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
          style: const TextStyle(color: AppTheme.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final username = controller.text.trim();
              if (username.isNotEmpty && username != widget.username) {
                Navigator.pop(context);
                _openChat(username);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: AppTheme.bg,
            ),
            child: const Text('Start Chat'),
          ),
        ],
      ),
    );
  }

  Color _getColorForUsername(String name) {
    const colors = [
      Color(0xFF00B89A),
      Color(0xFF5B8DD9),
      Color(0xFFD97B5B),
      Color(0xFF9B59B6),
      Color(0xFFE67E22),
      Color(0xFF3498DB),
      Color(0xFFE74C3C),
      Color(0xFF2ECC71),
    ];
    return colors[name.codeUnitAt(0) % colors.length];
  }
}