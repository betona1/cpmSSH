import 'package:equatable/equatable.dart';
import '../models/server_profile.dart';

abstract class ServerState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ServerInitial extends ServerState {}

class ServerLoading extends ServerState {}

class ServerLoaded extends ServerState {
  final List<ServerProfile> servers;
  ServerLoaded(this.servers);
  @override
  List<Object?> get props => [servers];
}

class ServerError extends ServerState {
  final String message;
  ServerError(this.message);
  @override
  List<Object?> get props => [message];
}
