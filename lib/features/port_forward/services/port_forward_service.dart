import 'dart:async';
import 'dart:io';
import 'package:dartssh2/dartssh2.dart';
import '../../../data/local/secure_storage.dart';
import '../models/port_forward_model.dart';

class ActiveForward {
  final SSHClient client;
  final ServerSocket serverSocket;
  final PortForwardConfig config;
  final List<StreamSubscription> _subscriptions = [];

  ActiveForward({
    required this.client,
    required this.serverSocket,
    required this.config,
  });

  void addSubscription(StreamSubscription sub) => _subscriptions.add(sub);

  Future<void> stop() async {
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    try { await serverSocket.close(); } catch (_) {}
    try { client.close(); } catch (_) {}
  }
}

class PortForwardService {
  final Map<String, ActiveForward> _activeForwards = {};

  bool isRunning(String id) => _activeForwards.containsKey(id);

  Future<void> start(PortForwardConfig config) async {
    if (_activeForwards.containsKey(config.id)) return;

    final password = await SecureStorageService.getPassword('pf_${config.id}');
    final privateKey = await SecureStorageService.getPrivateKey('pf_${config.id}');

    // Step 1: TCP connect to gateway
    SSHSocket socket;
    try {
      socket = await SSHSocket.connect(
        config.gatewayHost,
        config.gatewayPort,
        timeout: const Duration(seconds: 15),
      );
    } catch (e) {
      throw Exception('Cannot reach gateway ${config.gatewayHost}:${config.gatewayPort} - $e');
    }

    // Step 2: SSH auth
    SSHClient client;
    try {
      client = SSHClient(
        socket,
        username: config.gatewayUsername,
        onPasswordRequest: () => password ?? '',
        identities: privateKey != null ? SSHKeyPair.fromPem(privateKey) : [],
      );
    } catch (e) {
      throw Exception('SSH client error: $e');
    }

    // Step 3: Verify auth by running a test command
    try {
      final result = await client.run('echo __pf_ok__').timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('SSH auth timeout'),
      );
      final output = String.fromCharCodes(result);
      if (!output.contains('__pf_ok__')) {
        throw Exception('Unexpected response');
      }
    } catch (e) {
      client.close();
      throw Exception('SSH auth failed on ${config.gatewayHost}:${config.gatewayPort} as ${config.gatewayUsername} - $e');
    }

    // Step 4: Bind local port
    ServerSocket serverSocket;
    try {
      serverSocket = await ServerSocket.bind(
        InternetAddress.loopbackIPv4,
        config.localPort,
      );
    } catch (e) {
      client.close();
      throw Exception('Cannot bind localhost:${config.localPort} - $e');
    }

    final forward = ActiveForward(
      client: client,
      serverSocket: serverSocket,
      config: config,
    );

    // Step 5: Handle incoming TCP connections
    final sub = serverSocket.listen((Socket tcpSocket) async {
      try {
        final channel = await client.forwardLocal(
          config.remoteHost,
          config.remotePort,
        );

        // Pipe: TCP client → SSH channel
        tcpSocket.listen(
          (data) {
            try { channel.sink.add(data); } catch (_) {}
          },
          onDone: () => channel.sink.close(),
          onError: (_) => channel.sink.close(),
          cancelOnError: true,
        );

        // Pipe: SSH channel → TCP client
        channel.stream.listen(
          (data) {
            try { tcpSocket.add(data); } catch (_) {}
          },
          onDone: () => tcpSocket.destroy(),
          onError: (_) => tcpSocket.destroy(),
          cancelOnError: true,
        );
      } catch (e) {
        tcpSocket.destroy();
      }
    });

    forward.addSubscription(sub);
    _activeForwards[config.id] = forward;
  }

  Future<void> stop(String id) async {
    final forward = _activeForwards.remove(id);
    if (forward != null) {
      await forward.stop();
    }
  }

  Future<void> stopAll() async {
    for (final id in _activeForwards.keys.toList()) {
      await stop(id);
    }
  }
}
