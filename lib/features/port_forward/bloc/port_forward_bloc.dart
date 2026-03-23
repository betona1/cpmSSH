import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/port_forward_model.dart';
import '../services/port_forward_service.dart';
import '../repository/port_forward_repository.dart';
import '../../../data/local/secure_storage.dart';

// Events
abstract class PfEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class PfLoad extends PfEvent {}

class PfAdd extends PfEvent {
  final PortForwardConfig config;
  final String? password;
  final String? privateKey;
  PfAdd(this.config, {this.password, this.privateKey});
}

class PfUpdate extends PfEvent {
  final PortForwardConfig config;
  final String? password;
  final String? privateKey;
  PfUpdate(this.config, {this.password, this.privateKey});
}

class PfDelete extends PfEvent {
  final String id;
  PfDelete(this.id);
}

class PfStart extends PfEvent {
  final String id;
  PfStart(this.id);
}

class PfStop extends PfEvent {
  final String id;
  PfStop(this.id);
}

class PfToggle extends PfEvent {
  final String id;
  PfToggle(this.id);
}

class PfSetAutoStart extends PfEvent {
  final String id;
  final bool autoStart;
  PfSetAutoStart(this.id, this.autoStart);
}

class PfAutoStartAll extends PfEvent {}

// State
class PfState extends Equatable {
  final List<PortForwardState> forwards;
  final bool isLoading;

  const PfState({this.forwards = const [], this.isLoading = false});

  PfState copyWith({List<PortForwardState>? forwards, bool? isLoading}) =>
      PfState(
        forwards: forwards ?? this.forwards,
        isLoading: isLoading ?? this.isLoading,
      );

  @override
  List<Object?> get props => [forwards.length, isLoading,
    forwards.map((f) => '${f.config.id}:${f.status}').join(',')];
}

// BLoC
class PortForwardBloc extends Bloc<PfEvent, PfState> {
  final PortForwardService _service;
  final PortForwardRepository _repo;

  PortForwardBloc({
    required PortForwardService service,
    required PortForwardRepository repo,
  })  : _service = service,
        _repo = repo,
        super(const PfState()) {
    on<PfLoad>(_onLoad);
    on<PfAdd>(_onAdd);
    on<PfUpdate>(_onUpdate);
    on<PfDelete>(_onDelete);
    on<PfStart>(_onStart);
    on<PfStop>(_onStop);
    on<PfToggle>(_onToggle);
    on<PfSetAutoStart>(_onSetAutoStart);
    on<PfAutoStartAll>(_onAutoStartAll);
  }

  bool _firstLoad = true;

  Future<void> _onLoad(PfLoad event, Emitter<PfState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final configs = await _repo.getAll();
      final forwards = configs.map((c) => PortForwardState(
        config: c,
        status: _service.isRunning(c.id) ? ForwardStatus.running : ForwardStatus.stopped,
      )).toList();
      emit(state.copyWith(forwards: forwards, isLoading: false));

      // Auto-start on first load
      if (_firstLoad) {
        _firstLoad = false;
        for (final config in configs) {
          if (config.autoStart && !_service.isRunning(config.id)) {
            add(PfStart(config.id));
          }
        }
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> _onAdd(PfAdd event, Emitter<PfState> emit) async {
    await _repo.insert(event.config);
    if (event.password != null) {
      await SecureStorageService.savePassword('pf_${event.config.id}', event.password!);
    }
    if (event.privateKey != null) {
      await SecureStorageService.savePrivateKey('pf_${event.config.id}', event.privateKey!);
    }
    add(PfLoad());
  }

  Future<void> _onUpdate(PfUpdate event, Emitter<PfState> emit) async {
    // Stop if running, then update
    await _service.stop(event.config.id);
    await _repo.update(event.config);
    if (event.password != null) {
      await SecureStorageService.savePassword('pf_${event.config.id}', event.password!);
    }
    if (event.privateKey != null) {
      await SecureStorageService.savePrivateKey('pf_${event.config.id}', event.privateKey!);
    }
    add(PfLoad());
  }

  Future<void> _onDelete(PfDelete event, Emitter<PfState> emit) async {
    await _service.stop(event.id);
    await _repo.delete(event.id);
    await SecureStorageService.deleteCredentials('pf_${event.id}');
    add(PfLoad());
  }

  Future<void> _onStart(PfStart event, Emitter<PfState> emit) async {
    final idx = state.forwards.indexWhere((f) => f.config.id == event.id);
    if (idx < 0) return;

    final updated = List<PortForwardState>.from(state.forwards);
    updated[idx] = updated[idx].copyWith(status: ForwardStatus.connecting);
    emit(state.copyWith(forwards: updated));

    try {
      await _service.start(state.forwards[idx].config);
      final updated2 = List<PortForwardState>.from(state.forwards);
      final idx2 = updated2.indexWhere((f) => f.config.id == event.id);
      if (idx2 >= 0) {
        updated2[idx2] = updated2[idx2].copyWith(status: ForwardStatus.running);
        emit(state.copyWith(forwards: updated2));
      }
    } catch (e) {
      final updated2 = List<PortForwardState>.from(state.forwards);
      final idx2 = updated2.indexWhere((f) => f.config.id == event.id);
      if (idx2 >= 0) {
        updated2[idx2] = updated2[idx2].copyWith(
          status: ForwardStatus.error,
          errorMessage: e.toString(),
        );
        emit(state.copyWith(forwards: updated2));
      }
    }
  }

  Future<void> _onStop(PfStop event, Emitter<PfState> emit) async {
    await _service.stop(event.id);
    final updated = List<PortForwardState>.from(state.forwards);
    final idx = updated.indexWhere((f) => f.config.id == event.id);
    if (idx >= 0) {
      updated[idx] = updated[idx].copyWith(status: ForwardStatus.stopped);
      emit(state.copyWith(forwards: updated));
    }
  }

  Future<void> _onToggle(PfToggle event, Emitter<PfState> emit) async {
    if (_service.isRunning(event.id)) {
      add(PfStop(event.id));
    } else {
      add(PfStart(event.id));
    }
  }

  Future<void> _onSetAutoStart(PfSetAutoStart event, Emitter<PfState> emit) async {
    await _repo.setAutoStart(event.id, event.autoStart);
    add(PfLoad());
  }

  Future<void> _onAutoStartAll(PfAutoStartAll event, Emitter<PfState> emit) async {
    final configs = await _repo.getAll();
    for (final config in configs) {
      if (config.autoStart && !_service.isRunning(config.id)) {
        add(PfStart(config.id));
      }
    }
  }

  @override
  Future<void> close() {
    _service.stopAll();
    return super.close();
  }
}
