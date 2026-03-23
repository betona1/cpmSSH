import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../services/ssh_service.dart';
import '../../servers/repository/server_repository.dart';
import 'ssh_event.dart';
import 'ssh_state.dart';

class SshBloc extends Bloc<SshEvent, SshState> {
  final SshService _sshService;
  final ServerRepository _serverRepository;
  static const _uuid = Uuid();

  SshBloc({
    required SshService sshService,
    required ServerRepository serverRepository,
  })  : _sshService = sshService,
        _serverRepository = serverRepository,
        super(const SshState()) {
    on<SshConnect>(_onConnect);
    on<SshDisconnect>(_onDisconnect);
    on<SshSwitchTab>(_onSwitchTab);
    on<SshSendInput>(_onSendInput);
  }

  Future<void> _onConnect(SshConnect event, Emitter<SshState> emit) async {
    emit(state.copyWith(isConnecting: true, error: null));
    try {
      final connection = await _sshService.connect(event.server);
      final tabId = _uuid.v4();
      final tab = SshTab(
        id: tabId,
        server: event.server,
        connection: connection,
      );
      final newTabs = [...state.tabs, tab];
      emit(state.copyWith(
        tabs: newTabs,
        activeTabId: tabId,
        isConnecting: false,
      ));
      await _serverRepository.updateLastConnected(event.server.id);
    } catch (e) {
      emit(state.copyWith(
        isConnecting: false,
        error: 'Connection failed: ${e.toString()}',
      ));
    }
  }

  void _onDisconnect(SshDisconnect event, Emitter<SshState> emit) {
    final tab = state.tabs.where((t) => t.id == event.tabId).firstOrNull;
    tab?.connection.dispose();
    final newTabs = state.tabs.where((t) => t.id != event.tabId).toList();
    String? newActiveId;
    if (newTabs.isNotEmpty) {
      newActiveId = state.activeTabId == event.tabId
          ? newTabs.last.id
          : state.activeTabId;
    }
    emit(state.copyWith(tabs: newTabs, activeTabId: newActiveId));
  }

  void _onSwitchTab(SshSwitchTab event, Emitter<SshState> emit) {
    emit(state.copyWith(activeTabId: event.tabId));
  }

  void _onSendInput(SshSendInput event, Emitter<SshState> emit) {
    final tab = state.tabs.where((t) => t.id == event.tabId).firstOrNull;
    if (tab != null) {
      tab.connection.session.stdin.add(
        Uint8List.fromList(utf8.encode(event.input)),
      );
    }
  }

  @override
  Future<void> close() {
    for (final tab in state.tabs) {
      tab.connection.dispose();
    }
    return super.close();
  }
}
