import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:xterm/xterm.dart' hide TerminalThemes;
import '../../../core/theme/terminal_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../cpm/bloc/cpm_bloc.dart';
import '../../cpm/bloc/cpm_event.dart';
import '../../cpm/bloc/cpm_state.dart';
import '../../servers/screens/server_list_screen.dart';
import '../../port_forward/screens/port_forward_screen.dart';
import '../../cpm/screens/cpm_dashboard_screen.dart';
import '../../cpm/screens/prompt_history_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../bloc/ssh_bloc.dart';
import '../bloc/ssh_event.dart';
import '../bloc/ssh_state.dart';

class TerminalScreen extends StatefulWidget {
  const TerminalScreen({super.key});

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  final _focusNode = FocusNode(debugLabel: 'TerminalFocus');
  final _focusNode2 = FocusNode(debugLabel: 'TerminalFocus2');
  final _termController = TerminalController();
  final _termController2 = TerminalController();
  final _inputController = TextEditingController();
  final _inputFocusNode = FocusNode(debugLabel: 'InputBarFocus');
  bool _showInputBar = false;
  bool _dualMode = false;
  int _inputLines = 1;
  final List<String> _inputHistory = [];
  int _historyIndex = -1;
  int _activePanelIndex = 0; // 0=left/single, 1=right (for dual mode)

  bool get _isDesktop =>
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _focusNode2.dispose();
    _termController.dispose();
    _termController2.dispose();
    _inputController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  String? _getTargetTabId(SshState state) {
    if (!_dualMode || state.tabs.length < 2) return state.activeTabId;
    if (_activePanelIndex < state.tabs.length) return state.tabs[_activePanelIndex].id;
    return state.activeTabId;
  }

  void _sendTextInput(String text, SshState state) {
    final targetId = _getTargetTabId(state);
    if (text.trim().isNotEmpty && targetId != null) {
      final trimmed = text.replaceAll('\n', '').trim();
      if (trimmed.isNotEmpty) {
        _inputHistory.insert(0, trimmed);
        if (_inputHistory.length > 50) _inputHistory.removeLast();

        // Send to CPM server if connected
        final cpmState = context.read<CpmBloc>().state;
        if (cpmState.isConnected) {
          // Find project ID from server's cpmProjectId
          final tab = state.tabs.where((t) => t.id == targetId).firstOrNull;
          final projectId = tab?.server.cpmProjectId?.toString();
          if (projectId != null) {
            context.read<CpmBloc>().add(CpmSendPrompt(
              content: trimmed,
              projectId: projectId,
              tag: 'other',
            ));
          }
        }
      }
      _historyIndex = -1;

      context.read<SshBloc>().add(SshSendInput(targetId, text));
      _inputController.clear();
      setState(() => _inputLines = 1);
    }
    if (_activePanelIndex == 0) {
      _focusNode.requestFocus();
    } else {
      _focusNode2.requestFocus();
    }
  }

  void _navigateHistory(int direction) {
    if (_inputHistory.isEmpty) return;
    setState(() {
      _historyIndex += direction;
      if (_historyIndex < 0) _historyIndex = 0;
      if (_historyIndex >= _inputHistory.length) {
        _historyIndex = -1;
        _inputController.clear();
        return;
      }
      _inputController.text = _inputHistory[_historyIndex];
      _inputController.selection = TextSelection.fromPosition(
        TextPosition(offset: _inputController.text.length),
      );
    });
  }

  void _autoCopySelection(Terminal terminal, TerminalController ctrl) {
    final sel = ctrl.selection;
    if (sel != null) {
      final text = terminal.buffer.getText(sel);
      if (text.isNotEmpty) {
        Clipboard.setData(ClipboardData(text: text));
      }
    }
  }

  Widget _buildTerminalView(Terminal terminal, FocusNode focusNode, TerminalController ctrl, TerminalStyle style, {bool autofocus = false}) {
    // Auto-copy selection to clipboard (PuTTY style)
    ctrl.addListener(() => _autoCopySelection(terminal, ctrl));

    return TerminalView(
      terminal,
      focusNode: focusNode,
      controller: ctrl,
      autofocus: autofocus,
      hardwareKeyboardOnly: _isDesktop,
      theme: TerminalThemes.defaultTheme,
      textStyle: style,
      padding: EdgeInsets.zero,
      // Right-click = paste (PuTTY style)
      onSecondaryTapUp: (details, _) async {
        final data = await Clipboard.getData(Clipboard.kTextPlain);
        if (data?.text != null) {
          terminal.paste(data!.text!);
        }
      },
    );
  }

  TerminalStyle _getTerminalStyle(ThemeProvider tp) {
    return TerminalStyle(
      fontSize: tp.fontSize,
      fontFamily: tp.fontFamily,
      fontFamilyFallback: [
        tp.fontFamily,
        'Consolas',
        'Malgun Gothic',
        'D2Coding',
        'NanumGothicCoding',
        'Segoe UI Symbol',
        'Segoe UI Emoji',
        'monospace',
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return BlocBuilder<SshBloc, SshState>(
      builder: (context, state) {
        if (state.isConnecting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Connecting...')),
            body: const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Establishing SSH connection...')])),
          );
        }

        if (state.error != null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Connection Error')),
            body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Text(state.error!, textAlign: TextAlign.center)),
              const SizedBox(height: 16),
              FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Go Back')),
            ])),
          );
        }

        if (state.tabs.isEmpty) {
          return Scaffold(appBar: AppBar(title: const Text('Terminal')), body: const Center(child: Text('No active sessions')));
        }

        final scaffoldKey = GlobalKey<ScaffoldState>();
        final termStyle = _getTerminalStyle(themeProvider);

        return Scaffold(
          key: scaffoldKey,
          endDrawer: _NavigationDrawer(onNavigate: (path) {
            Navigator.pop(context); // close drawer
            Widget? screen;
            switch (path) {
              case '/': screen = const ServerListScreen(); break;
              case '/tunnel': screen = const PortForwardScreen(); break;
              case '/cpm': screen = const CpmDashboardScreen(); break;
              case '/prompts': screen = const PromptHistoryScreen(); break;
              case '/settings': screen = const SettingsScreen(); break;
            }
            if (screen != null) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => screen!));
            }
          }),
          body: SafeArea(
            child: Column(
              children: [
                // Toolbar
                _Toolbar(
                  tabs: state.tabs,
                  activeTabId: state.activeTabId,
                  dualMode: _dualMode,
                  isDark: themeProvider.isDark,
                  onMenuTap: () => scaffoldKey.currentState?.openEndDrawer(),
                  onDualToggle: () {
                    if (state.tabs.length < 2 && !_dualMode) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Connect 2 servers to use dual mode'), duration: Duration(seconds: 2)),
                      );
                      return;
                    }
                    setState(() => _dualMode = !_dualMode);
                  },
                  onThemeToggle: () => themeProvider.toggleTheme(),
                ),
                // Terminal area
                Expanded(
                  child: _dualMode && state.tabs.length >= 2
                      ? Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() { _activePanelIndex = 0; _focusNode.requestFocus(); }),
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: _activePanelIndex == 0 ? Theme.of(context).colorScheme.primary : Colors.transparent,
                                      width: _activePanelIndex == 0 ? 2 : 0,
                                    ),
                                  ),
                                  child: _buildTerminalView(state.tabs[0].terminal, _focusNode, _termController, termStyle, autofocus: true),
                                ),
                              ),
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() { _activePanelIndex = 1; _focusNode2.requestFocus(); }),
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: _activePanelIndex == 1 ? Theme.of(context).colorScheme.primary : Colors.transparent,
                                      width: _activePanelIndex == 1 ? 2 : 0,
                                    ),
                                  ),
                                  child: _buildTerminalView(state.tabs[1].terminal, _focusNode2, _termController2, termStyle),
                                ),
                              ),
                            ),
                          ],
                        )
                      : state.activeTab != null
                          ? _buildTerminalView(state.activeTab!.terminal, _focusNode, _termController, termStyle, autofocus: true)
                          : const SizedBox.shrink(),
                ),
                // Input bar
                if (_showInputBar)
                  _InputBar(
                    controller: _inputController,
                    focusNode: _inputFocusNode,
                    lines: _inputLines,
                    onSend: (text) => _sendTextInput('$text\n', state),
                    onExpand: () => setState(() => _inputLines = _inputLines >= 3 ? 1 : _inputLines + 1),
                    onHistoryUp: () => _navigateHistory(1),
                    onHistoryDown: () => _navigateHistory(-1),
                    onClose: () {
                      setState(() => _showInputBar = false);
                      _focusNode.requestFocus();
                    },
                  ),
              ],
            ),
          ),
          floatingActionButton: (state.activeTab != null && !_showInputBar)
              ? FloatingActionButton.small(
                  onPressed: () {
                    setState(() => _showInputBar = true);
                    WidgetsBinding.instance.addPostFrameCallback((_) => _inputFocusNode.requestFocus());
                  },
                  tooltip: 'Input (한글)',
                  child: const Text('한', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                )
              : null,
        );
      },
    );
  }
}

// ═══════════════════════════════════════════
// Toolbar
// ═══════════════════════════════════════════
class _Toolbar extends StatelessWidget {
  final List<SshTab> tabs;
  final String? activeTabId;
  final bool dualMode;
  final bool isDark;
  final VoidCallback onMenuTap;
  final VoidCallback onDualToggle;
  final VoidCallback onThemeToggle;

  const _Toolbar({
    required this.tabs, this.activeTabId, required this.dualMode,
    required this.isDark, required this.onMenuTap,
    required this.onDualToggle, required this.onThemeToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      color: const Color(0xFF1E1E1E),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          // Session tabs
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(top: 6, bottom: 2),
              itemCount: tabs.length,
              itemBuilder: (context, index) {
                final tab = tabs[index];
                final isActive = tab.id == activeTabId;
                final colors = [Colors.lightBlue, Colors.lightGreen, Colors.amber, Colors.purpleAccent, Colors.tealAccent];
                final tabColor = colors[index % colors.length];
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: GestureDetector(
                    onTap: () => context.read<SshBloc>().add(SshSwitchTab(tab.id)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFF2D2D2D) : const Color(0xFF151515),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                        border: Border(
                          top: BorderSide(color: tabColor, width: 3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.computer, size: 14, color: tabColor),
                          const SizedBox(width: 8),
                          Text(
                            tab.server.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                              color: isActive ? Colors.white : Colors.white60,
                            ),
                          ),
                          const SizedBox(width: 10),
                          InkWell(
                            onTap: () => context.read<SshBloc>().add(SshDisconnect(tab.id)),
                            child: Icon(Icons.close, size: 14, color: isActive ? Colors.white54 : Colors.white30),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // CPM status
          BlocBuilder<CpmBloc, CpmState>(
            builder: (context, cpmState) {
              return Tooltip(
                message: cpmState.isConnected ? 'CPM Connected' : 'CPM Disconnected',
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: cpmState.isConnected ? Colors.green.withAlpha(30) : Colors.red.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: cpmState.isConnected ? Colors.green : Colors.red, width: 0.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('CPM', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: cpmState.isConnected ? Colors.green : Colors.red)),
                      const SizedBox(width: 2),
                      Icon(
                        cpmState.isConnected ? Icons.link : Icons.link_off,
                        size: 12,
                        color: cpmState.isConnected ? Colors.green : Colors.red,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // Dual mode toggle
          IconButton(
            icon: Icon(dualMode ? Icons.splitscreen : Icons.crop_square, size: 18),
            onPressed: onDualToggle,
            tooltip: dualMode ? 'Single' : 'Dual',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32),
          ),
          // Theme toggle
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, size: 18),
            onPressed: onThemeToggle,
            tooltip: isDark ? 'Light' : 'Dark',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32),
          ),
          // Menu
          IconButton(
            icon: const Icon(Icons.menu, size: 18),
            onPressed: onMenuTap,
            tooltip: 'Menu',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// Input Bar with history, expand, shift+enter
// ═══════════════════════════════════════════
class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final int lines;
  final void Function(String) onSend;
  final VoidCallback onExpand;
  final VoidCallback onHistoryUp;
  final VoidCallback onHistoryDown;
  final VoidCallback onClose;

  const _InputBar({
    required this.controller, required this.focusNode, required this.lines,
    required this.onSend, required this.onExpand,
    required this.onHistoryUp, required this.onHistoryDown, required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Expand button
          IconButton(
            icon: Icon(lines >= 3 ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up, size: 18),
            onPressed: onExpand,
            tooltip: lines >= 3 ? 'Collapse' : 'Expand',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32),
          ),
          // History buttons
          IconButton(
            icon: const Icon(Icons.arrow_upward, size: 16),
            onPressed: onHistoryUp,
            tooltip: 'Previous',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_downward, size: 16),
            onPressed: onHistoryDown,
            tooltip: 'Next',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28),
          ),
          const SizedBox(width: 4),
          // Text field
          Expanded(
            child: KeyboardListener(
              focusNode: FocusNode(),
              onKeyEvent: (event) {
                // We handle shift+enter in the TextField's onSubmitted and keyEvent
              },
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                autofocus: true,
                maxLines: lines,
                style: const TextStyle(fontFamily: 'Consolas', fontSize: 14),
                decoration: InputDecoration(
                  hintText: lines > 1 ? 'Shift+Enter: newline, Enter: send' : 'Type here (Korean OK)...',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (text) {
                  if (text.isNotEmpty) onSend(text);
                },
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.send, size: 18),
            onPressed: () {
              if (controller.text.isNotEmpty) onSend(controller.text);
            },
            tooltip: 'Send',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: onClose,
            tooltip: 'Close',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// Navigation Drawer
// ═══════════════════════════════════════════
class _NavigationDrawer extends StatelessWidget {
  final void Function(String path) onNavigate;
  const _NavigationDrawer({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('cpmSSH', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimaryContainer)),
                  const SizedBox(height: 4),
                  Text('SSH Terminal & CPM Manager', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onPrimaryContainer)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ListTile(leading: const Icon(Icons.dns), title: const Text('Servers'), onTap: () => onNavigate('/')),
            ListTile(leading: const Icon(Icons.swap_horiz), title: const Text('Port Forwarding'), onTap: () => onNavigate('/tunnel')),
            ListTile(leading: const Icon(Icons.dashboard), title: const Text('CPM Dashboard'), onTap: () => onNavigate('/cpm')),
            ListTile(leading: const Icon(Icons.chat), title: const Text('Prompt History'), onTap: () => onNavigate('/prompts')),
            const Divider(),
            ListTile(leading: const Icon(Icons.settings), title: const Text('Settings'), onTap: () => onNavigate('/settings')),
          ],
        ),
      ),
    );
  }
}
