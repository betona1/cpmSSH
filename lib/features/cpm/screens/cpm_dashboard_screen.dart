import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants.dart';
import '../bloc/cpm_bloc.dart';
import '../bloc/cpm_event.dart';
import '../bloc/cpm_state.dart';
import '../models/cpm_models.dart';

class CpmDashboardScreen extends StatefulWidget {
  const CpmDashboardScreen({super.key});

  @override
  State<CpmDashboardScreen> createState() => _CpmDashboardScreenState();
}

class _CpmDashboardScreenState extends State<CpmDashboardScreen> {
  bool _favoritesOnly = true;

  @override
  void initState() {
    super.initState();
    context.read<CpmBloc>().add(CpmCheckConnection());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CPM Dashboard'),
        actions: [
          BlocBuilder<CpmBloc, CpmState>(
            builder: (context, state) => IconButton(
              icon: Icon(
                state.isConnected ? Icons.cloud_done : Icons.cloud_off,
                color: state.isConnected ? Colors.green : Colors.red,
              ),
              onPressed: () => context.read<CpmBloc>().add(CpmCheckConnection()),
            ),
          ),
        ],
      ),
      body: BlocBuilder<CpmBloc, CpmState>(
        builder: (context, state) {
          if (!state.isConnected) {
            return _DisconnectedView(onRetry: () => context.read<CpmBloc>().add(CpmCheckConnection()));
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<CpmBloc>().add(CpmLoadStats());
              context.read<CpmBloc>().add(CpmLoadProjects());
            },
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                // Stats row
                _StatsRow(stats: state.stats),
                const SizedBox(height: 16),

                // Projects header with filter
                Row(
                  children: [
                    Text('Projects', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 12),
                    _FilterChip(
                      icon: Icons.favorite,
                      label: 'Favorites',
                      selected: _favoritesOnly,
                      color: Colors.red,
                      onTap: () => setState(() => _favoritesOnly = true),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      icon: Icons.apps,
                      label: 'All',
                      selected: !_favoritesOnly,
                      color: Theme.of(context).colorScheme.primary,
                      onTap: () => setState(() => _favoritesOnly = false),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Project cards grid
                _ProjectGrid(
                  projects: _favoritesOnly
                      ? state.projects.where((p) => p.favorited).toList()
                      : state.projects,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DisconnectedView extends StatelessWidget {
  final VoidCallback onRetry;
  const _DisconnectedView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('CPM Server Not Connected'),
          const SizedBox(height: 8),
          Text('Check port forwarding (Tunnel tab)', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Retry')),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final CpmStats stats;
  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCard('Total Prompts', '${stats.totalPrompts}', Colors.blue)),
        const SizedBox(width: 8),
        Expanded(child: _StatCard('Projects', '${stats.totalProjects}', Colors.green)),
        const SizedBox(width: 8),
        Expanded(child: _StatCard('Days', '${stats.workingDays}', Colors.orange)),
        const SizedBox(width: 8),
        Expanded(child: _StatCard('Tokens', stats.totalTokensFormatted, Colors.red)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatCard(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label, style: Theme.of(context).textTheme.bodySmall, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _FilterChip({required this.icon, required this.label, required this.selected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? color.withAlpha(30) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? color : Colors.grey.withAlpha(80)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: selected ? color : Colors.grey),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12, color: selected ? color : Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _ProjectGrid extends StatelessWidget {
  final List<CpmProject> projects;
  const _ProjectGrid({required this.projects});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 900 ? 3 : (width > 600 ? 2 : 1);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 1.2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: projects.length,
      itemBuilder: (context, index) => _ProjectCard(project: projects[index]),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final CpmProject project;
  const _ProjectCard({required this.project});

  String? get _screenshotUrl {
    if (project.screenshot == null || project.screenshot!.isEmpty) return null;
    return '${CpmConfig.baseUrl}/static/${project.screenshot}';
  }

  @override
  Widget build(BuildContext context) {
    final p = project;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // Show screenshot fullscreen if available
          if (_screenshotUrl != null) {
            showDialog(
              context: context,
              builder: (_) => Dialog(
                child: InteractiveViewer(
                  child: Image.network(_screenshotUrl!, errorBuilder: (_, e, s) => const SizedBox.shrink()),
                ),
              ),
            );
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Screenshot banner
            if (_screenshotUrl != null)
              SizedBox(
                height: 60,
                width: double.infinity,
                child: Image.network(
                  _screenshotUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, e, s) => Container(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: const Center(child: Icon(Icons.image_not_supported, size: 20)),
                  ),
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              // Top row: days + tokens
              Row(
                children: [
                  Text('${p.daysSinceCreated}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue)),
                  Text('days', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                  const SizedBox(width: 12),
                  Text(p.totalTokensFormatted, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                  Text('tokens', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                  const Spacer(),
                  if (p.favorited)
                    const Icon(Icons.favorite, color: Colors.red, size: 16),
                  const SizedBox(width: 4),
                  // Prompt count badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${p.promptCount}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimaryContainer)),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Project name
              Text(
                p.name,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // Server info badge
              if (p.serverInfo != null && p.serverInfo!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(30),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(p.serverInfo!, style: const TextStyle(fontSize: 10, fontFamily: 'monospace'), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              const SizedBox(height: 4),

              // Description
              if (p.description != null && p.description!.isNotEmpty)
                Expanded(
                  child: Text(
                    p.description!,
                    style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

              const Spacer(),

              // Bottom row: links
              Row(
                children: [
                  if (p.githubUrl != null && p.githubUrl!.isNotEmpty)
                    _LinkIcon(Icons.code, 'GitHub', () => _openUrl(p.githubUrl!)),
                  if (p.url != null && p.url!.isNotEmpty)
                    _LinkIcon(Icons.language, 'Dev', () => _openUrl(p.url!)),
                  if (p.deployUrl != null && p.deployUrl!.isNotEmpty)
                    _LinkIcon(Icons.rocket_launch, 'Prod', () => _openUrl(p.deployUrl!)),
                ],
              ),
            ],
          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openUrl(String url) {
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}

class _LinkIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _LinkIcon(this.icon, this.tooltip, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Tooltip(
          message: tooltip,
          child: Icon(icon, size: 16, color: Colors.grey[500]),
        ),
      ),
    );
  }
}
