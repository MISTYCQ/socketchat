import 'package:flutter/material.dart';
import '../services/socket_service.dart';
import '../theme.dart';
import 'chat_screen.dart';

/// LoginScreen - Connection setup interface
/// 
/// Allows user to:
/// - Enter username
/// - Configure server host and port
/// - Connect to chat server
/// - Handle connection errors
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _hostController = TextEditingController(text: '127.0.0.1');
  final _portController = TextEditingController(text: '12345');
  
  bool _connecting = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  /// Validate inputs and connect to server
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

    // Create socket service
    final service = SocketService();

    try {
      // Attempt connection
      await service.connect(
        host: host,
        port: port,
        username: username,
      );

      // Connection successful - navigate to chat
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              service: service,
              username: username,
            ),
          ),
        );
      }
    } catch (e) {
      // Connection failed
      setState(() => _connecting = false);
      service.dispose();
      
      String errorMsg = 'Connection failed';
      if (e.toString().contains('failed host lookup')) {
        errorMsg = 'Invalid host address';
      } else if (e.toString().contains('Connection refused')) {
        errorMsg = 'Server is not running or refused connection';
      } else if (e.toString().contains('timed out')) {
        errorMsg = 'Connection timed out';
      }
      
      _showError(errorMsg);
    }
  }

  /// Show error message
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
                // App icon/logo
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
                  'Real-time TCP chat application',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 48),

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

                // Server host field
                TextField(
                  controller: _hostController,
                  decoration: const InputDecoration(
                    labelText: 'Server Host',
                    labelStyle: TextStyle(color: AppTheme.textSecondary),
                    prefixIcon: Icon(Icons.dns, color: AppTheme.accent),
                    helperText: 'e.g., 127.0.0.1 or 192.168.1.100',
                    helperStyle: TextStyle(color: AppTheme.systemText),
                  ),
                  style: const TextStyle(color: AppTheme.textPrimary),
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.number,
                  enabled: !_connecting,
                ),
                const SizedBox(height: 16),

                // Server port field
                TextField(
                  controller: _portController,
                  decoration: const InputDecoration(
                    labelText: 'Server Port',
                    labelStyle: TextStyle(color: AppTheme.textSecondary),
                    prefixIcon: Icon(Icons.settings_ethernet, color: AppTheme.accent),
                    helperText: 'Default: 12345',
                    helperStyle: TextStyle(color: AppTheme.systemText),
                  ),
                  style: const TextStyle(color: AppTheme.textPrimary),
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _connect(),
                  enabled: !_connecting,
                ),
                const SizedBox(height: 32),

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

                // Instructions
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
                        '📋 Getting Started',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.accent,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '1. Start the Python server: python server.py\n'
                        '2. Enter your username\n'
                        '3. Configure server host and port\n'
                        '4. Click "Connect to Server"',
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