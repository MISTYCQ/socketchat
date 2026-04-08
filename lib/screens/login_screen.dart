import 'package:flutter/material.dart';
import '../services/enhanced_socket_service.dart';
import '../services/storage_service.dart';
import '../theme.dart';
import 'contacts_screen.dart';

/// Enhanced LoginScreen with username history
/// 
/// Features:
/// - Username autocomplete from history
/// - Recent usernames dropdown
/// - Server configuration
/// - Connection status
class EnhancedLoginScreen extends StatefulWidget {
  const EnhancedLoginScreen({super.key});

  @override
  State<EnhancedLoginScreen> createState() => _EnhancedLoginScreenState();
}

class _EnhancedLoginScreenState extends State<EnhancedLoginScreen> {
  final _usernameController = TextEditingController();
  final _hostController = TextEditingController(text: '127.0.0.1');
  final _portController = TextEditingController(text: '12345');

  bool _connecting = false;
  List<String> _recentUsers = [];

  @override
  void initState() {
    super.initState();
    _loadRecentUsers();
  }

  Future<void> _loadRecentUsers() async {
    final recent = await StorageService.getRecentUsers();
    final lastUser = await StorageService.getLastUsername();

    setState(() {
      _recentUsers = recent;
      if (lastUser != null && lastUser.isNotEmpty) {
        _usernameController.text = lastUser;
      }
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final username = _usernameController.text.trim();
    final host = _hostController.text.trim();
    final portText = _portController.text.trim();

    // Validation
    if (username.isEmpty) {
      _showError('Please enter a username');
      return;
    }

    if (host.isEmpty) {
      _showError('Please enter server host');
      return;
    }

    final port = int.tryParse(portText);
    if (port == null || port < 1 || port > 65535) {
      _showError('Please enter a valid port (1-65535)');
      return;
    }

    setState(() => _connecting = true);

    final service = EnhancedSocketService();

    try {
      await service.connect(
        host: host,
        port: port,
        username: username,
      );

      // Save username to history
      await StorageService.saveRecentUser(username);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ContactsScreen(
              service: service,
              username: username,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _connecting = false);
      service.dispose();

      String errorMsg = 'Connection failed';
      if (e.toString().contains('failed host lookup')) {
        errorMsg = 'Invalid host address';
      } else if (e.toString().contains('Connection refused')) {
        errorMsg = 'Server is not running or refused connection';
      } else if (e.toString().contains('timed out')) {
        errorMsg = 'Connection timed out';
      } else if (e.toString().contains('already taken')) {
        errorMsg = 'Username already in use. Please choose another.';
      }

      _showError(errorMsg);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _selectRecentUser(String username) {
    setState(() {
      _usernameController.text = username;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // App icon
                Icon(
                  Icons.chat_bubble_rounded,
                  size: 80,
                  color: AppTheme.accent,
                ),
                const SizedBox(height: 24),

                // Title
                const Text(
                  'Socket Chat',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Real-time messaging with private chats',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 48),

                // Recent users chips
                if (_recentUsers.isNotEmpty) ...[
                  const Text(
                    'Recent usernames:',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _recentUsers.take(5).map((username) {
                      return ActionChip(
                        label: Text(username),
                        onPressed: () => _selectRecentUser(username),
                        backgroundColor: AppTheme.surfaceAlt,
                        labelStyle: const TextStyle(
                          color: AppTheme.accent,
                          fontSize: 12,
                        ),
                        avatar: Icon(
                          Icons.person,
                          size: 16,
                          color: AppTheme.accent,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],

                // Username field
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    labelStyle: TextStyle(color: AppTheme.textSecondary),
                    prefixIcon: Icon(Icons.person, color: AppTheme.accent),
                  ),
                  style: const TextStyle(color: AppTheme.textPrimary),
                  textInputAction: TextInputAction.next,
                  enabled: !_connecting,
                ),
                const SizedBox(height: 16),

                // Server settings (collapsible)
                Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                  ),
                  child: ExpansionTile(
                    title: const Text(
                      'Server Settings',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    iconColor: AppTheme.accent,
                    collapsedIconColor: AppTheme.textSecondary,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            TextField(
                              controller: _hostController,
                              decoration: const InputDecoration(
                                labelText: 'Server Host',
                                labelStyle:
                                    TextStyle(color: AppTheme.textSecondary),
                                prefixIcon: Icon(Icons.dns, color: AppTheme.accent),
                                helperText: 'e.g., 127.0.0.1 or 192.168.1.100',
                                helperStyle:
                                    TextStyle(color: AppTheme.systemText),
                              ),
                              style: const TextStyle(color: AppTheme.textPrimary),
                              textInputAction: TextInputAction.next,
                              keyboardType: TextInputType.number,
                              enabled: !_connecting,
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _portController,
                              decoration: const InputDecoration(
                                labelText: 'Server Port',
                                labelStyle:
                                    TextStyle(color: AppTheme.textSecondary),
                                prefixIcon: Icon(Icons.settings_ethernet,
                                    color: AppTheme.accent),
                                helperText: 'Default: 12345',
                                helperStyle:
                                    TextStyle(color: AppTheme.systemText),
                              ),
                              style: const TextStyle(color: AppTheme.textPrimary),
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _connect(),
                              enabled: !_connecting,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Connect button
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _connecting ? null : _connect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      foregroundColor: AppTheme.bg,
                      disabledBackgroundColor: AppTheme.surfaceAlt,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _connecting
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.bg,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('Connecting...'),
                            ],
                          )
                        : const Text(
                            'Connect to Server',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // Quick info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        '✨ Features',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.accent,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '• Private messaging with contacts\n'
                        '• See who\'s online in real-time\n'
                        '• Username history & quick login\n'
                        '• Save favorite contacts',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}