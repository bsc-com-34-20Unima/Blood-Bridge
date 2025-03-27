import 'package:socket_io_client/socket_io_client.dart' as socket_io;
import 'package:logger/logger.dart';

class SocketService {
  late socket_io.Socket socket;
  final String backendUrl;
  final Future<String> Function()? getToken; // Token provider
  final String userId;
  final Logger _logger = Logger();
  bool _isConnected = false;

  SocketService(this.backendUrl, {required this.getToken, required this.userId});

  Future<void> connect() async {
    if (_isConnected) return; // Prevent duplicate connections

    String? token = await getToken?.call();
    if (token == null) {
      _logger.e("Failed to retrieve token");
      return;
    }

    socket = socket_io.io(
      backendUrl,
      socket_io.OptionBuilder()
        .setTransports(['websocket'])
        .enableAutoConnect()
        .setExtraHeaders({'Authorization': 'Bearer $token'})
        .setReconnectionAttempts(5) // Retry 5 times if disconnected
        .setReconnectionDelay(2000) // Wait 2s before retry
        .build(),
    );

    socket.onConnect((_) {
      _isConnected = true;
      _logger.i('Connected to WebSocket');
      socket.emit('register', {'userId': userId});
    });

    socket.onDisconnect((_) {
      _isConnected = false;
      _logger.w('Disconnected from WebSocket');
    });

    socket.onError((err) => _logger.e('Socket error: $err'));
    socket.onReconnect((_) => _logger.i('Reconnecting...'));
  }

  void listen(String event, Function(dynamic) callback) {
    if (!_isConnected) {
      _logger.w("Cannot listen, socket not connected");
      return;
    }
    socket.on(event, callback);
  }

  void emit(String event, dynamic data) {
    if (!_isConnected) {
      _logger.w("Cannot emit, socket not connected");
      return;
    }
    socket.emit(event, data);
  }

  void disconnect() {
    if (!_isConnected) return;
    socket.dispose();
    _isConnected = false;
    _logger.i('Socket disconnected and disposed');
  }
}
