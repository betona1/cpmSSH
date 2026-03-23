import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants.dart';
import '../../../data/remote/cpm_client.dart';
import 'cpm_event.dart';
import 'cpm_state.dart';

class CpmBloc extends Bloc<CpmEvent, CpmState> {
  CpmApiClient _client;

  CpmBloc() : _client = CpmApiClient(CpmConfig.baseUrl), super(const CpmState()) {
    on<CpmCheckConnection>(_onCheckConnection);
    on<CpmLoadProjects>(_onLoadProjects);
    on<CpmLoadPrompts>(_onLoadPrompts);
    on<CpmLoadStats>(_onLoadStats);
    on<CpmLoadServices>(_onLoadServices);
    on<CpmSendPrompt>(_onSendPrompt);
    on<CpmUpdateBaseUrl>(_onUpdateBaseUrl);
  }

  Future<void> _onCheckConnection(CpmCheckConnection event, Emitter<CpmState> emit) async {
    final connected = await _client.checkConnection();
    emit(state.copyWith(isConnected: connected));
    if (connected) {
      add(CpmLoadStats());
      add(CpmLoadProjects());
    }
  }

  Future<void> _onLoadProjects(CpmLoadProjects event, Emitter<CpmState> emit) async {
    try {
      final projects = await _client.getProjects();
      emit(state.copyWith(projects: projects));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onLoadPrompts(CpmLoadPrompts event, Emitter<CpmState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final prompts = await _client.getPrompts(
        projectId: event.projectId,
        search: event.search,
      );
      emit(state.copyWith(prompts: prompts, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onLoadStats(CpmLoadStats event, Emitter<CpmState> emit) async {
    try {
      final stats = await _client.getStats();
      emit(state.copyWith(stats: stats));
    } catch (_) {}
  }

  Future<void> _onLoadServices(CpmLoadServices event, Emitter<CpmState> emit) async {
    try {
      final services = await _client.getServices();
      emit(state.copyWith(services: services));
    } catch (_) {}
  }

  Future<void> _onSendPrompt(CpmSendPrompt event, Emitter<CpmState> emit) async {
    try {
      await _client.sendPrompt(
        content: event.content,
        projectId: event.projectId,
        tag: event.tag,
      );
      add(CpmLoadPrompts(projectId: event.projectId));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  void _onUpdateBaseUrl(CpmUpdateBaseUrl event, Emitter<CpmState> emit) {
    CpmConfig.baseUrl = event.baseUrl;
    _client = CpmApiClient(event.baseUrl);
    add(CpmCheckConnection());
  }
}
