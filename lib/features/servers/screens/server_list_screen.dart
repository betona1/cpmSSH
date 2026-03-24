import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/server_bloc.dart';
import '../bloc/server_event.dart';
import '../bloc/server_state.dart';
import '../models/server_profile.dart';
import '../../ssh/bloc/ssh_bloc.dart';
import '../../ssh/bloc/ssh_event.dart';
import '../../ssh/bloc/ssh_state.dart';
import '../../ssh/screens/terminal_screen.dart';

class ServerListScreen extends StatelessWidget {
  const ServerListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('cpmSSH'),
        actions: [
          // Active sessions button
          BlocBuilder<SshBloc, SshState>(
            builder: (context, sshState) {
              if (sshState.tabs.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: FilledButton.tonalIcon(
                  onPressed: () {
                    context.push('/terminal');
                  },
                  icon: const Icon(Icons.terminal, size: 18),
                  label: Text('${sshState.tabs.length} Session${sshState.tabs.length > 1 ? 's' : ''}'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: const Size(0, 34),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<ServerBloc, ServerState>(
        builder: (context, state) {
          if (state is ServerLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ServerError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          if (state is ServerLoaded) {
            if (state.servers.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.dns_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
                    const SizedBox(height: 16),
                    Text(
                      'No servers yet',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap + to add your first server',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ],
                ),
              );
            }
            return _ServerList(servers: state.servers);
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/server/add'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ServerList extends StatelessWidget {
  final List<ServerProfile> servers;

  const _ServerList({required this.servers});

  @override
  Widget build(BuildContext context) {
    // Group servers
    final grouped = <String, List<ServerProfile>>{};
    for (final server in servers) {
      final group = server.group ?? 'Ungrouped';
      grouped.putIfAbsent(group, () => []).add(server);
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: servers.length,
      itemBuilder: (context, index) {
        final server = servers[index];
        return _ServerCard(server: server);
      },
    );
  }
}

class _ServerCard extends StatelessWidget {
  final ServerProfile server;

  const _ServerCard({required this.server});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            Icons.computer,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(server.name),
        subtitle: Text(
          '${server.username}@${server.host}:${server.port}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
              ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (server.isFavorite)
              Icon(Icons.star, color: Theme.of(context).colorScheme.primary, size: 20),
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              tooltip: 'Edit',
              onPressed: () => context.push('/server/edit/${server.id}'),
            ),
            IconButton(
              icon: const Icon(Icons.play_arrow, color: Colors.green),
              tooltip: 'Connect',
              onPressed: () {
                context.read<SshBloc>().add(SshConnect(server));
                context.push('/terminal');
              },
            ),
          ],
        ),
        onTap: () {
          context.read<SshBloc>().add(SshConnect(server));
          context.push('/terminal');
        },
        onLongPress: () {
          _showServerOptions(context, server);
        },
      ),
    );
  }

  void _showServerOptions(BuildContext context, ServerProfile server) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/server/edit/${server.id}');
              },
            ),
            ListTile(
              leading: Icon(server.isFavorite ? Icons.star_border : Icons.star),
              title: Text(server.isFavorite ? 'Remove from favorites' : 'Add to favorites'),
              onTap: () {
                Navigator.pop(ctx);
                context.read<ServerBloc>().add(
                      ToggleFavorite(server.id, !server.isFavorite),
                    );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                context.read<ServerBloc>().add(DeleteServer(server.id));
              },
            ),
          ],
        ),
      ),
    );
  }
}
