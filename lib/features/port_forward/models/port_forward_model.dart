import 'package:equatable/equatable.dart';

enum ForwardType { local, remote }
enum ForwardStatus { stopped, connecting, running, error }

class PortForwardConfig extends Equatable {
  final String id;
  final String name;
  // SSH Gateway (jump server)
  final String gatewayHost;
  final int gatewayPort;
  final String gatewayUsername;
  // Forward config
  final ForwardType type;
  final int localPort;
  final String remoteHost;
  final int remotePort;
  final bool autoStart;
  final DateTime createdAt;

  const PortForwardConfig({
    required this.id,
    required this.name,
    required this.gatewayHost,
    this.gatewayPort = 22,
    required this.gatewayUsername,
    this.type = ForwardType.local,
    required this.localPort,
    required this.remoteHost,
    required this.remotePort,
    this.autoStart = false,
    required this.createdAt,
  });

  String get summary => 'localhost:$localPort → $remoteHost:$remotePort';
  String get gateway => '$gatewayUsername@$gatewayHost:$gatewayPort';

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'gateway_host': gatewayHost,
        'gateway_port': gatewayPort,
        'gateway_username': gatewayUsername,
        'type': type.name,
        'local_port': localPort,
        'remote_host': remoteHost,
        'remote_port': remotePort,
        'auto_start': autoStart ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
      };

  factory PortForwardConfig.fromMap(Map<String, dynamic> m) => PortForwardConfig(
        id: m['id'] as String,
        name: m['name'] as String,
        gatewayHost: m['gateway_host'] as String,
        gatewayPort: m['gateway_port'] as int? ?? 22,
        gatewayUsername: m['gateway_username'] as String,
        type: ForwardType.values.firstWhere(
          (e) => e.name == m['type'],
          orElse: () => ForwardType.local,
        ),
        localPort: m['local_port'] as int,
        remoteHost: m['remote_host'] as String,
        remotePort: m['remote_port'] as int,
        autoStart: (m['auto_start'] as int?) == 1,
        createdAt: DateTime.parse(m['created_at'] as String),
      );

  @override
  List<Object?> get props => [id];
}

class PortForwardState {
  final PortForwardConfig config;
  final ForwardStatus status;
  final String? errorMessage;

  PortForwardState({
    required this.config,
    this.status = ForwardStatus.stopped,
    this.errorMessage,
  });

  PortForwardState copyWith({
    ForwardStatus? status,
    String? errorMessage,
  }) =>
      PortForwardState(
        config: config,
        status: status ?? this.status,
        errorMessage: errorMessage,
      );
}
