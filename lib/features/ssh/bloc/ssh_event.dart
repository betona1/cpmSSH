import 'package:equatable/equatable.dart';
import '../../servers/models/server_profile.dart';

abstract class SshEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class SshConnect extends SshEvent {
  final ServerProfile server;
  SshConnect(this.server);
  @override
  List<Object?> get props => [server];
}

class SshDisconnect extends SshEvent {
  final String tabId;
  SshDisconnect(this.tabId);
  @override
  List<Object?> get props => [tabId];
}

class SshSwitchTab extends SshEvent {
  final String tabId;
  SshSwitchTab(this.tabId);
  @override
  List<Object?> get props => [tabId];
}

class SshSendInput extends SshEvent {
  final String tabId;
  final String input;
  SshSendInput(this.tabId, this.input);
  @override
  List<Object?> get props => [tabId, input];
}

class SshResizeTerminal extends SshEvent {
  final String tabId;
  final int width;
  final int height;
  SshResizeTerminal(this.tabId, this.width, this.height);
  @override
  List<Object?> get props => [tabId, width, height];
}
