import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/port_forward_bloc.dart';
import '../models/port_forward_model.dart';
import 'port_forward_add_screen.dart';

class PortForwardScreen extends StatefulWidget {
  const PortForwardScreen({super.key});

  @override
  State<PortForwardScreen> createState() => _PortForwardScreenState();
}

class _PortForwardScreenState extends State<PortForwardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<PortForwardBloc>().add(PfLoad());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Port Forwarding'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<PortForwardBloc>().add(PfLoad()),
          ),
        ],
      ),
      body: BlocBuilder<PortForwardBloc, PfState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.forwards.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.swap_horiz, size: 64,
                      color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 16),
                  Text('No port forwards',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text('Tap + to create SSH tunnel',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline)),
                  const SizedBox(height: 24),
                  _ExampleCard(),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: state.forwards.length,
            itemBuilder: (context, index) {
              return _ForwardCard(forward: state.forwards[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => BlocProvider.value(
              value: context.read<PortForwardBloc>(),
              child: const PortForwardAddScreen(),
            )),
          );
          if (result == true && context.mounted) {
            context.read<PortForwardBloc>().add(PfLoad());
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ForwardCard extends StatelessWidget {
  final PortForwardState forward;
  const _ForwardCard({required this.forward});

  Color _statusColor(ForwardStatus status) {
    switch (status) {
      case ForwardStatus.running:
        return Colors.green;
      case ForwardStatus.connecting:
        return Colors.orange;
      case ForwardStatus.error:
        return Colors.red;
      case ForwardStatus.stopped:
        return Colors.grey;
    }
  }

  IconData _statusIcon(ForwardStatus status) {
    switch (status) {
      case ForwardStatus.running:
        return Icons.check_circle;
      case ForwardStatus.connecting:
        return Icons.sync;
      case ForwardStatus.error:
        return Icons.error;
      case ForwardStatus.stopped:
        return Icons.stop_circle_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = forward.config;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              _statusIcon(forward.status),
              color: _statusColor(forward.status),
              size: 28,
            ),
            title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                // Forward route
                Row(
                  children: [
                    _Chip('localhost:${c.localPort}', Colors.blue),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(Icons.arrow_forward, size: 14),
                    ),
                    _Chip('${c.remoteHost}:${c.remotePort}', Colors.orange),
                  ],
                ),
                const SizedBox(height: 4),
                // Gateway
                Text(
                  'via ${c.gateway}',
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                // Auto-start toggle
                Row(
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: c.autoStart,
                        onChanged: (v) {
                          context.read<PortForwardBloc>().add(PfSetAutoStart(c.id, v ?? false));
                        },
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('Auto-start', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.outline)),
                  ],
                ),
                if (forward.errorMessage != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    forward.errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 11),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Start/Stop toggle
                IconButton(
                  icon: Icon(
                    forward.status == ForwardStatus.running
                        ? Icons.stop_circle
                        : Icons.play_circle,
                    color: forward.status == ForwardStatus.running
                        ? Colors.red
                        : Colors.green,
                    size: 32,
                  ),
                  onPressed: forward.status == ForwardStatus.connecting
                      ? null
                      : () => context.read<PortForwardBloc>().add(PfToggle(c.id)),
                ),
                // Edit
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () async {
                    final result = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(builder: (_) => BlocProvider.value(
                        value: context.read<PortForwardBloc>(),
                        child: PortForwardAddScreen(editConfig: c),
                      )),
                    );
                    if (result == true && context.mounted) {
                      context.read<PortForwardBloc>().add(PfLoad());
                    }
                  },
                ),
                // Delete
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () => _confirmDelete(context, c),
                ),
              ],
            ),
          ),
          // Status bar
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: _statusColor(forward.status).withAlpha(forward.status == ForwardStatus.running ? 255 : 80),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, PortForwardConfig c) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete forward?'),
        content: Text('Delete "${c.name}"?\n${c.summary}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<PortForwardBloc>().add(PfDelete(c.id));
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final Color color;
  const _Chip(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: color),
      ),
    );
  }
}

class _ExampleCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Example', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            const Text(
              'Office SSH → Home access:\n'
              'localhost:2222 → 192.168.219.100:22\n'
              'via your-gateway.com',
              style: TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
