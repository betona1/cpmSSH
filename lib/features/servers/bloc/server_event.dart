import 'package:equatable/equatable.dart';
import '../models/server_profile.dart';

abstract class ServerEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadServers extends ServerEvent {}

class AddServer extends ServerEvent {
  final ServerProfile server;
  final String? password;
  final String? privateKey;
  AddServer(this.server, {this.password, this.privateKey});
  @override
  List<Object?> get props => [server];
}

class UpdateServer extends ServerEvent {
  final ServerProfile server;
  final String? password;
  final String? privateKey;
  UpdateServer(this.server, {this.password, this.privateKey});
  @override
  List<Object?> get props => [server];
}

class DeleteServer extends ServerEvent {
  final String serverId;
  DeleteServer(this.serverId);
  @override
  List<Object?> get props => [serverId];
}

class ToggleFavorite extends ServerEvent {
  final String serverId;
  final bool isFavorite;
  ToggleFavorite(this.serverId, this.isFavorite);
  @override
  List<Object?> get props => [serverId, isFavorite];
}
