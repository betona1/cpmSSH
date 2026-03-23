import 'package:equatable/equatable.dart';
import '../models/cpm_models.dart';

class CpmState extends Equatable {
  final bool isConnected;
  final bool isLoading;
  final List<CpmProject> projects;
  final List<CpmPrompt> prompts;
  final List<CpmServicePort> services;
  final CpmStats stats;
  final String? error;

  const CpmState({
    this.isConnected = false,
    this.isLoading = false,
    this.projects = const [],
    this.prompts = const [],
    this.services = const [],
    this.stats = const CpmStats(),
    this.error,
  });

  CpmState copyWith({
    bool? isConnected,
    bool? isLoading,
    List<CpmProject>? projects,
    List<CpmPrompt>? prompts,
    List<CpmServicePort>? services,
    CpmStats? stats,
    String? error,
  }) {
    return CpmState(
      isConnected: isConnected ?? this.isConnected,
      isLoading: isLoading ?? this.isLoading,
      projects: projects ?? this.projects,
      prompts: prompts ?? this.prompts,
      services: services ?? this.services,
      stats: stats ?? this.stats,
      error: error,
    );
  }

  @override
  List<Object?> get props => [isConnected, isLoading, projects, prompts, services, stats, error];
}
