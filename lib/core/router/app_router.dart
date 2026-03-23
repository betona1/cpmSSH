import 'package:go_router/go_router.dart';
import '../../features/servers/screens/server_list_screen.dart';
import '../../features/servers/screens/server_edit_screen.dart';
import '../../features/ssh/screens/terminal_screen.dart';
import '../../features/cpm/screens/cpm_dashboard_screen.dart';
import '../../features/cpm/screens/prompt_history_screen.dart';
import '../../features/port_forward/screens/port_forward_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../shell_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) => ShellScreen(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const ServerListScreen(),
          ),
          GoRoute(
            path: '/tunnel',
            builder: (context, state) => const PortForwardScreen(),
          ),
          GoRoute(
            path: '/cpm',
            builder: (context, state) => const CpmDashboardScreen(),
          ),
          GoRoute(
            path: '/prompts',
            builder: (context, state) => const PromptHistoryScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/server/add',
        builder: (context, state) => const ServerEditScreen(),
      ),
      GoRoute(
        path: '/server/edit/:id',
        builder: (context, state) => ServerEditScreen(
          serverId: state.pathParameters['id'],
        ),
      ),
      GoRoute(
        path: '/terminal',
        builder: (context, state) => const TerminalScreen(),
      ),
    ],
  );
}
