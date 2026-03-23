import 'dart:convert';
import 'dart:typed_data';
import 'package:dartssh2/dartssh2.dart';
import 'package:xterm/xterm.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants.dart';
import '../../../data/local/secure_storage.dart';
import '../../servers/models/server_profile.dart';

// Regex to detect URLs in terminal output
final _urlRegex = RegExp(r'https?://[^\s\x1b\]]+');

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
    } else {
      privateKey = await SecureStorageService.getPrivateKey(server.id);
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

    void detectAndOpenUrl(String text) {
      outputBuffer.write(text);
      // Only check buffer periodically (when we have enough text)
      if (outputBuffer.length > 50) {
        final bufStr = outputBuffer.toString();
        final matches = _urlRegex.allMatches(bufStr);
        for (final match in matches) {
          final url = match.group(0)!;
          // Auto-open Claude/Anthropic login URLs
          if (url.contains('anthropic.com') || url.contains('claude.ai') || url.contains('console.anthropic')) {
            final now = DateTime.now();
            // Debounce: don't open same URL within 5 seconds
            if (lastUrlLaunch == null || now.difference(lastUrlLaunch!).inSeconds > 5) {
              lastUrlLaunch = now;
              launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
            }
          }
        }
        // Keep only last 200 chars for next detection
        if (outputBuffer.length > 200) {
          final keep = bufStr.substring(bufStr.length - 100);
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
