import 'dart:convert';
import 'dart:typed_data';
import 'package:dartssh2/dartssh2.dart';
import 'package:xterm/xterm.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants.dart';
import '../../../data/local/secure_storage.dart';
import '../../servers/models/server_profile.dart';

// Regex to detect URLs - strip ANSI escape sequences first
final _ansiRegex = RegExp(r'\x1b\[[0-9;]*[a-zA-Z]|\x1b\][^\x07]*\x07|\x1b[^[](.)');
final _urlRegex = RegExp(r'https?://[^\s<>"]+');

class SshConnection {
  final SSHClient client;
  final SSHSession session;
  final Terminal terminal;

  SshConnection({
    required this.client,
    required this.session,
    required this.terminal,
  });

  void dispose() {
    session.close();
    client.close();
  }
}

class SshService {
  Future<SshConnection> connect(ServerProfile server) async {
    String? password;
    String? privateKey;

    if (server.authMethod == AuthMethod.password) {
      password = await SecureStorageService.getPassword(server.id);
      if (password == null || password.isEmpty) {
        throw Exception('비밀번호가 저장되어 있지 않습니다. 서버를 편집하여 비밀번호를 입력해주세요.');
      }
    } else {
      privateKey = await SecureStorageService.getPrivateKey(server.id);
      if (privateKey == null || privateKey.isEmpty) {
        throw Exception('Private Key가 저장되어 있지 않습니다. 서버를 편집하여 키 파일을 선택해주세요.');
      }
    }

    final socket = await SSHSocket.connect(
      server.host,
      server.port,
      timeout: Duration(seconds: AppConstants.sshConnectTimeoutSeconds),
    );

    final client = SSHClient(
      socket,
      username: server.username,
      onPasswordRequest: () => password ?? '',
      identities: privateKey != null
          ? SSHKeyPair.fromPem(privateKey)
          : [],
    );

    final terminal = Terminal(
      maxLines: AppConstants.terminalScrollbackLines,
    );

    final session = await client.shell(
      pty: SSHPtyConfig(
        width: 80,
        height: 24,
        type: 'xterm-256color',
      ),
    );

    // UTF-8 decoder that handles partial multi-byte sequences across chunks
    final stdoutDecoder = Utf8Decoder(allowMalformed: true);
    final stderrDecoder = Utf8Decoder(allowMalformed: true);

    // Buffer for URL detection across chunks
    final outputBuffer = StringBuffer();
    DateTime? lastUrlLaunch;

    final Set<String> openedUrls = {};

    void detectAndOpenUrl(String text) {
      outputBuffer.write(text);
      if (outputBuffer.length > 30) {
        // Strip ANSI escape sequences before URL detection
        final clean = outputBuffer.toString().replaceAll(_ansiRegex, '');
        final matches = _urlRegex.allMatches(clean);
        for (final match in matches) {
          var url = match.group(0)!;
          // Clean trailing punctuation
          while (url.endsWith('.') || url.endsWith(',') || url.endsWith(')')) {
            url = url.substring(0, url.length - 1);
          }
          // Auto-open Claude/Anthropic login URLs
          if (url.contains('anthropic.com') || url.contains('claude.ai') ||
              url.contains('claude.com') || url.contains('console.anthropic') ||
              url.contains('oauth')) {
            final now = DateTime.now();
            if (!openedUrls.contains(url) ||
                (lastUrlLaunch != null && now.difference(lastUrlLaunch!).inSeconds > 30)) {
              lastUrlLaunch = now;
              openedUrls.add(url);
              launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
            }
          }
        }
        // Keep buffer manageable
        if (outputBuffer.length > 500) {
          final keep = clean.substring(clean.length - 200);
          outputBuffer.clear();
          outputBuffer.write(keep);
        }
      }
    }

    // Connect SSH stdout to terminal (proper UTF-8 decoding + URL detection)
    session.stdout.cast<List<int>>().listen((data) {
      final text = stdoutDecoder.convert(data);
      terminal.write(text);
      detectAndOpenUrl(text);
    });

    session.stderr.cast<List<int>>().listen((data) {
      final text = stderrDecoder.convert(data);
      terminal.write(text);
      detectAndOpenUrl(text);
    });

    // Connect terminal input to SSH stdin
    terminal.onOutput = (data) {
      session.stdin.add(Uint8List.fromList(utf8.encode(data)));
    };

    // tmux 세션 자동 연결: 있으면 attach, 없으면 새로 생성
    if (server.tmuxEnabled) {
      final sessionName = server.tmuxSession?.isNotEmpty == true
          ? server.tmuxSession!
          : 'cpm-shared';
      // -A: attach if exists, create if not
      // -s: session name
      session.stdin.add(
        Uint8List.fromList(utf8.encode('tmux new-session -As $sessionName\n')),
      );
    }

    // Execute initial directory change
    if (server.initialDir != null && server.initialDir!.isNotEmpty) {
      session.stdin.add(
        Uint8List.fromList(utf8.encode('cd ${server.initialDir}\n')),
      );
    }

    // Execute initial command
    if (server.initCommand != null && server.initCommand!.isNotEmpty) {
      session.stdin.add(
        Uint8List.fromList(utf8.encode('${server.initCommand}\n')),
      );
    }

    return SshConnection(
      client: client,
      session: session,
      terminal: terminal,
    );
  }
}
