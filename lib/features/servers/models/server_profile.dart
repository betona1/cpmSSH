import 'package:equatable/equatable.dart';

enum AuthMethod { password, privateKey }

class ServerProfile extends Equatable {
  final String id;
  final String name;
  final String host;
  final int port;
  final String username;
  final AuthMethod authMethod;
  final String? group;
  final String? initialDir;
  final String? initCommand;
  final int? cpmProjectId;
  final bool isFavorite;
  final DateTime? lastConnectedAt;
  final DateTime createdAt;

  const ServerProfile({
    required this.id,
    required this.name,
    required this.host,
    this.port = 22,
    required this.username,
    this.authMethod = AuthMethod.password,
    this.group,
    this.initialDir,
    this.initCommand,
    this.cpmProjectId,
    this.isFavorite = false,
    this.lastConnectedAt,
    required this.createdAt,
  });

  ServerProfile copyWith({
    String? id,
    String? name,
    String? host,
    int? port,
    String? username,
    AuthMethod? authMethod,
    String? group,
    String? initialDir,
    String? initCommand,
    int? cpmProjectId,
    bool? isFavorite,
    DateTime? lastConnectedAt,
    DateTime? createdAt,
  }) {
    return ServerProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      authMethod: authMethod ?? this.authMethod,
      group: group ?? this.group,
      initialDir: initialDir ?? this.initialDir,
      initCommand: initCommand ?? this.initCommand,
      cpmProjectId: cpmProjectId ?? this.cpmProjectId,
      isFavorite: isFavorite ?? this.isFavorite,
      lastConnectedAt: lastConnectedAt ?? this.lastConnectedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'host': host,
      'port': port,
      'username': username,
      'auth_method': authMethod.name,
      'group_name': group,
      'initial_dir': initialDir,
      'init_command': initCommand,
      'cpm_project_id': cpmProjectId,
      'is_favorite': isFavorite ? 1 : 0,
      'last_connected_at': lastConnectedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ServerProfile.fromMap(Map<String, dynamic> map) {
    return ServerProfile(
      id: map['id'] as String,
      name: map['name'] as String,
      host: map['host'] as String,
      port: map['port'] as int? ?? 22,
      username: map['username'] as String,
      authMethod: AuthMethod.values.firstWhere(
        (e) => e.name == map['auth_method'],
        orElse: () => AuthMethod.password,
      ),
      group: map['group_name'] as String?,
      initialDir: map['initial_dir'] as String?,
      initCommand: map['init_command'] as String?,
      cpmProjectId: map['cpm_project_id'] as int?,
      isFavorite: (map['is_favorite'] as int?) == 1,
      lastConnectedAt: map['last_connected_at'] != null
          ? DateTime.parse(map['last_connected_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  @override
  List<Object?> get props => [id, name, host, port, username, authMethod, group];
}
