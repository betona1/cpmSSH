import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../features/cpm/models/cpm_models.dart';

class CpmApiClient {
  final String baseUrl;

  CpmApiClient(this.baseUrl);

  Future<bool> checkConnection() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/api/stats/'))
          .timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Parse DRF paginated response or plain list
  List<dynamic> _parseList(String body) {
    final decoded = jsonDecode(body);
    if (decoded is List) return decoded;
    if (decoded is Map && decoded.containsKey('results')) {
      return decoded['results'] as List;
    }
    return [];
  }

  Future<List<CpmProject>> getProjects() async {
    final res = await http.get(Uri.parse('$baseUrl/api/projects/'));
    if (res.statusCode != 200) throw Exception('Failed to load projects');
    final data = _parseList(res.body);
    return data.map((e) => CpmProject.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<CpmPrompt>> getPrompts({String? projectId, String? search}) async {
    final params = <String, String>{};
    if (projectId != null) params['project'] = projectId;
    if (search != null) params['search'] = search;
    final uri = Uri.parse('$baseUrl/api/prompts/').replace(queryParameters: params.isEmpty ? null : params);
    final res = await http.get(uri);
    if (res.statusCode != 200) throw Exception('Failed to load prompts');
    final data = _parseList(res.body);
    return data.map((e) => CpmPrompt.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> sendPrompt({
    required String content,
    required String projectId,
    String tag = 'other',
  }) async {
    await http.post(
      Uri.parse('$baseUrl/api/prompts/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'content': content,
        'project': projectId,
        'tag': tag,
        'source': 'cpm-ssh-terminal',
      }),
    );
  }

  Future<List<CpmServicePort>> getServices() async {
    final res = await http.get(Uri.parse('$baseUrl/api/services/'));
    if (res.statusCode != 200) throw Exception('Failed to load services');
    final data = _parseList(res.body);
    return data.map((e) => CpmServicePort.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<CpmStats> getStats() async {
    final res = await http.get(Uri.parse('$baseUrl/api/stats/'));
    if (res.statusCode != 200) throw Exception('Failed to load stats');
    return CpmStats.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }
}
