import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/server_repository.dart';
import 'server_event.dart';
import 'server_state.dart';

class ServerBloc extends Bloc<ServerEvent, ServerState> {
  final ServerRepository _repository;

  ServerBloc({required ServerRepository repository})
      : _repository = repository,
        super(ServerInitial()) {
    on<LoadServers>(_onLoad);
    on<AddServer>(_onAdd);
    on<UpdateServer>(_onUpdate);
    on<DeleteServer>(_onDelete);
    on<ToggleFavorite>(_onToggleFavorite);
  }

  Future<void> _onLoad(LoadServers event, Emitter<ServerState> emit) async {
    emit(ServerLoading());
    try {
      final servers = await _repository.getAll();
      emit(ServerLoaded(servers));
    } catch (e) {
      emit(ServerError(e.toString()));
    }
  }

  Future<void> _onAdd(AddServer event, Emitter<ServerState> emit) async {
    try {
      await _repository.insert(event.server,
          password: event.password, privateKey: event.privateKey);
      add(LoadServers());
    } catch (e) {
      emit(ServerError(e.toString()));
    }
  }

  Future<void> _onUpdate(UpdateServer event, Emitter<ServerState> emit) async {
    try {
      await _repository.update(event.server,
          password: event.password, privateKey: event.privateKey);
      add(LoadServers());
    } catch (e) {
      emit(ServerError(e.toString()));
    }
  }

  Future<void> _onDelete(DeleteServer event, Emitter<ServerState> emit) async {
    try {
      await _repository.delete(event.serverId);
      add(LoadServers());
    } catch (e) {
      emit(ServerError(e.toString()));
    }
  }

  Future<void> _onToggleFavorite(ToggleFavorite event, Emitter<ServerState> emit) async {
    try {
      await _repository.toggleFavorite(event.serverId, event.isFavorite);
      add(LoadServers());
    } catch (_) {}
  }
}
