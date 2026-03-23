import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class CpmWebSocketService {
  WebSocketChannel? _channel;
  final _eventController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get events => _eventController.stream;

  void connect(String wsUrl) {
    disconnect();
    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _channel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message as String) as Map<String, dynamic>;
            _eventController.add(data);
          } catch (_) {}
        },
        onError: (_) {},
        onDone: () {
          // Auto-reconnect after 5 seconds
          Future.delayed(const Duration(seconds: 5), () => connect(wsUrl));
        },
      );
    } catch (_) {}
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    disconnect();
    _eventController.close();
  }
}
