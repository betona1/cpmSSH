import 'package:equatable/equatable.dart';

class CpmProject extends Equatable {
  final int id;
  final String name;
  final String path;
  final String? description;
  final String? url;
  final String? deployUrl;
  final String? serverInfo;
  final String? githubUrl;
  final String? screenshot;
  final bool favorited;
  final int promptCount;
  final int successCount;
  final int failCount;
  final int wipCount;
  final int totalInputTokens;
  final int totalOutputTokens;
  final int totalCacheReadTokens;
  final int totalCacheCreateTokens;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CpmProject({
    required this.id,
    required this.name,
    this.path = '',
    this.description,
    this.url,
    this.deployUrl,
    this.serverInfo,
    this.githubUrl,
    this.screenshot,
    this.favorited = false,
    this.promptCount = 0,
    this.successCount = 0,
    this.failCount = 0,
    this.wipCount = 0,
    this.totalInputTokens = 0,
    this.totalOutputTokens = 0,
    this.totalCacheReadTokens = 0,
    this.totalCacheCreateTokens = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  int get totalTokens => totalInputTokens + totalOutputTokens;

  String get totalTokensFormatted {
    final t = totalInputTokens + totalOutputTokens + totalCacheReadTokens + totalCacheCreateTokens;
    if (t >= 1000000000) return '${(t / 1000000000).toStringAsFixed(1)}B';
    if (t >= 1000000) return '${(t / 1000000).toStringAsFixed(1)}M';
    if (t >= 1000) return '${(t / 1000).toStringAsFixed(1)}K';
    return t.toString();
  }

  int get daysSinceCreated => DateTime.now().difference(createdAt).inDays;

  factory CpmProject.fromJson(Map<String, dynamic> json) {
    return CpmProject(
      id: json['id'] as int,
      name: json['name'] as String,
      path: (json['path'] as String?) ?? '',
      description: json['description'] as String?,
      url: json['url'] as String?,
      deployUrl: json['deploy_url'] as String?,
      serverInfo: json['server_info'] as String?,
      githubUrl: json['github_url'] as String?,
      screenshot: json['screenshot'] as String?,
      favorited: (json['favorited'] as bool?) ?? false,
      promptCount: (json['prompt_count'] as int?) ?? 0,
      successCount: (json['success_count'] as int?) ?? 0,
      failCount: (json['fail_count'] as int?) ?? 0,
      wipCount: (json['wip_count'] as int?) ?? 0,
      totalInputTokens: (json['total_input_tokens'] as int?) ?? 0,
      totalOutputTokens: (json['total_output_tokens'] as int?) ?? 0,
      totalCacheReadTokens: (json['total_cache_read_tokens'] as int?) ?? 0,
      totalCacheCreateTokens: (json['total_cache_create_tokens'] as int?) ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  @override
  List<Object?> get props => [id, name];
}

class CpmPrompt extends Equatable {
  final int id;
  final String content;
  final String status;
  final String tag;
  final int? projectId;
  final String? projectName;
  final String source;
  final DateTime createdAt;

  const CpmPrompt({
    required this.id,
    required this.content,
    this.status = 'pending',
    this.tag = 'other',
    this.projectId,
    this.projectName,
    this.source = '',
    required this.createdAt,
  });

  factory CpmPrompt.fromJson(Map<String, dynamic> json) {
    // project can be int or map
    int? projectId;
    String? projectName;
    if (json['project'] is int) {
      projectId = json['project'] as int;
    } else if (json['project'] is Map) {
      projectId = json['project']['id'] as int?;
      projectName = json['project']['name'] as String?;
    }
    return CpmPrompt(
      id: json['id'] as int,
      content: json['content'] as String,
      status: (json['status'] as String?) ?? 'pending',
      tag: (json['tag'] as String?) ?? 'other',
      projectId: projectId,
      projectName: (json['project_name'] as String?) ?? projectName,
      source: (json['source'] as String?) ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  List<Object?> get props => [id, content, projectId];
}

class CpmServicePort extends Equatable {
  final int id;
  final String host;
  final int port;
  final String serviceName;
  final bool isOpen;
  final String? remarks;

  const CpmServicePort({
    required this.id,
    required this.host,
    required this.port,
    this.serviceName = '',
    this.isOpen = false,
    this.remarks,
  });

  factory CpmServicePort.fromJson(Map<String, dynamic> json) {
    return CpmServicePort(
      id: json['id'] as int,
      host: json['host'] as String,
      port: json['port'] as int,
      serviceName: (json['service_name'] as String?) ?? '',
      isOpen: (json['is_open'] as bool?) ?? false,
      remarks: json['remarks'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, host, port];
}

class CpmStats extends Equatable {
  final int totalProjects;
  final int totalPrompts;
  final int totalTokens;
  final int successCount;
  final int failCount;
  final int wipCount;
  final int workingDays;

  const CpmStats({
    this.totalProjects = 0,
    this.totalPrompts = 0,
    this.totalTokens = 0,
    this.successCount = 0,
    this.failCount = 0,
    this.wipCount = 0,
    this.workingDays = 0,
  });

  String get totalTokensFormatted {
    if (totalTokens >= 1000000) return '${(totalTokens / 1000000).toStringAsFixed(1)}M';
    if (totalTokens >= 1000) return '${(totalTokens / 1000).toStringAsFixed(1)}K';
    return totalTokens.toString();
  }

  factory CpmStats.fromJson(Map<String, dynamic> json) {
    return CpmStats(
      totalProjects: (json['projects'] as int?) ?? (json['total_projects'] as int?) ?? 0,
      totalPrompts: (json['total_prompts'] as int?) ?? 0,
      totalTokens: (json['total_tokens'] as int?) ?? 0,
      successCount: (json['success'] as int?) ?? 0,
      failCount: (json['fail'] as int?) ?? 0,
      wipCount: (json['wip'] as int?) ?? 0,
      workingDays: (json['working_days'] as int?) ?? 0,
    );
  }

  @override
  List<Object?> get props => [totalProjects, totalPrompts, totalTokens];
}
