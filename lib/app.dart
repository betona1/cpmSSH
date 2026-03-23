import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/router/app_router.dart';
import 'features/ssh/bloc/ssh_bloc.dart';
import 'features/ssh/services/ssh_service.dart';
import 'features/servers/bloc/server_bloc.dart';
import 'features/servers/bloc/server_event.dart';
import 'features/servers/repository/server_repository.dart';
import 'features/cpm/bloc/cpm_bloc.dart';
import 'features/cpm/bloc/cpm_event.dart';
import 'features/port_forward/bloc/port_forward_bloc.dart';
import 'features/port_forward/services/port_forward_service.dart';
import 'features/port_forward/repository/port_forward_repository.dart';

class CpmSshTerminalApp extends StatelessWidget {
  final ThemeProvider themeProvider;
  const CpmSshTerminalApp({super.key, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    final serverRepository = ServerRepository();
    final sshService = SshService();
    final pfService = PortForwardService();
    final pfRepo = PortForwardRepository();

    return ChangeNotifierProvider.value(
      value: themeProvider,
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => ServerBloc(repository: serverRepository)..add(LoadServers())),
          BlocProvider(create: (_) => SshBloc(sshService: sshService, serverRepository: serverRepository)),
          BlocProvider(create: (_) => CpmBloc()..add(CpmCheckConnection())),
          BlocProvider(create: (_) => PortForwardBloc(service: pfService, repo: pfRepo)..add(PfLoad())),
        ],
        child: Consumer<ThemeProvider>(
          builder: (context, tp, _) {
            return MaterialApp.router(
              title: 'cpmSSH',
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: tp.mode,
              routerConfig: AppRouter.router,
              debugShowCheckedModeBanner: false,
            );
          },
        ),
      ),
    );
  }
}
