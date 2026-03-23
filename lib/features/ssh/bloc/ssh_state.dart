import 'package:equatable/equatable.dart';
import 'package:xterm/xterm.dart';
import '../../servers/models/server_profile.dart';
import '../services/ssh_service.dart';

class SshTab {
  final String id;
  final ServerProfile server;
  final SshConnection connection;

  SshTab({
    required this.id,
    required this.server,
    required this.connection,
  });

  Terminal get terminal => connection.terminal;
}

class SshState extends Equatable {
  final List<SshTab> tabs;
  final String? activeTabId;
  final bool isConnecting;
  final String? error;

  const SshState({
    this.tabs = const [],
    this.activeTabId,
    this.isConnecting = false,
    this.error,
  });

  SshTab? get activeTab {
    if (activeTabId == null) return null;
    try {
      return tabs.firstWhere((t) => t.id == activeTabId);
    } catch (_) {
      return null;
    }
  }

  SshState copyWith({
    List<SshTab>? tabs,
    String? activeTabId,
    bool? isConnecting,
    String? error,
  }) {
    return SshState(
      tabs: tabs ?? this.tabs,
      activeTabId: activeTabId ?? this.activeTabId,
      isConnecting: isConnecting ?? this.isConnecting,
      error: error,
    );
  }

  @override
  List<Object?> get props => [tabs.length, activeTabId, isConnecting, error];
}
