import 'package:equatable/equatable.dart';

abstract class CpmEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class CpmCheckConnection extends CpmEvent {}

class CpmLoadProjects extends CpmEvent {}

class CpmLoadPrompts extends CpmEvent {
  final String? projectId;
  final String? search;
  CpmLoadPrompts({this.projectId, this.search});
  @override
  List<Object?> get props => [projectId, search];
}

class CpmLoadStats extends CpmEvent {}

class CpmLoadServices extends CpmEvent {}

class CpmSendPrompt extends CpmEvent {
  final String content;
  final String projectId;
  final String tag;
  CpmSendPrompt({required this.content, required this.projectId, this.tag = 'other'});
  @override
  List<Object?> get props => [content, projectId, tag];
}

class CpmUpdateBaseUrl extends CpmEvent {
  final String baseUrl;
  CpmUpdateBaseUrl(this.baseUrl);
  @override
  List<Object?> get props => [baseUrl];
}
