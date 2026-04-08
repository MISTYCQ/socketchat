import 'dart:async';
import 'dart:convert';
import 'dart:io';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  Socket? _socket;
  StreamSubscription? _socketSub;

  final StreamController<String> _controller =
      StreamController<String>.broadcast();

  Stream<String> get messages => _controller.stream;

  bool get isConnected => _socket != null;

  Future<void> connect({
    required String host,
    required int port,
    required String username,
  }) async {
    if (_socket != null) return; // ✅ prevent multiple connections

    try {
      _socket = await Socket.connect(host, port);

      _socket!.write("$username\n");

      _socketSub = _socket!
          .cast<List<int>>() // ✅ FIXED TYPE
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
        (line) {
          print("🔥 RECEIVED: $line");
          _controller.add(line);
        },
        onError: (e) {
          disconnect();
        },
        onDone: () {
          disconnect();
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  void sendMessage(String msg) {
    _socket?.write("$msg\n");
  }

  void disconnect() {
    _socketSub?.cancel();
    _socketSub = null;

    _socket?.destroy();
    _socket = null;
  }

  void dispose() {
    disconnect();
    _controller.close();
  }
}