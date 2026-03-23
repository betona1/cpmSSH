import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/cpm_bloc.dart';
import '../bloc/cpm_event.dart';
import '../bloc/cpm_state.dart';
import '../models/cpm_models.dart';

class PromptHistoryScreen extends StatefulWidget {
  const PromptHistoryScreen({super.key});

  @override
  State<PromptHistoryScreen> createState() => _PromptHistoryScreenState();
}

class _PromptHistoryScreenState extends State<PromptHistoryScreen> {
  int? _selectedProjectId;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final bloc = context.read<CpmBloc>();
    if (bloc.state.projects.isEmpty) {
      bloc.add(CpmLoadProjects());
    }
    bloc.add(CpmLoadPrompts());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadPrompts() {
    context.read<CpmBloc>().add(CpmLoadPrompts(
          projectId: _selectedProjectId?.toString(),
          search: _searchController.text.isEmpty ? null : _searchController.text,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<CpmBloc, CpmState>(
          builder: (context, state) {
            return Text('All Prompts (${state.stats.totalPrompts})');
          },
        ),
      ),
      body: BlocBuilder<CpmBloc, CpmState>(
        builder: (context, state) {
          if (!state.isConnected) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('CPM Server Not Connected'),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search prompts...',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _loadPrompts();
                            },
                          )
                        : null,
                  ),
                  onSubmitted: (_) => _loadPrompts(),
                ),
              ),

              // Project tabs
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  children: [
                    _ProjectTab(
                      label: 'All',
                      selected: _selectedProjectId == null,
                      onTap: () {
                        setState(() => _selectedProjectId = null);
                        _loadPrompts();
                      },
                    ),
                    ...state.projects
                        .where((p) => p.favorited || p.promptCount > 0)
                        .map((p) => _ProjectTab(
                              label: p.name,
                              count: p.promptCount,
                              selected: _selectedProjectId == p.id,
                              onTap: () {
                                setState(() => _selectedProjectId = p.id);
                                _loadPrompts();
                              },
                            )),
                  ],
                ),
              ),

              // Prompt list
              Expanded(
                child: state.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : state.prompts.isEmpty
                        ? const Center(child: Text('No prompts found'))
                        : ListView.builder(
                            itemCount: state.prompts.length,
                            itemBuilder: (context, index) {
                              return _PromptRow(
                                prompt: state.prompts[index],
                                projects: state.projects,
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProjectTab extends StatelessWidget {
  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  const _ProjectTab({
    required this.label,
    this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: selected
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 4),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    color: selected
                        ? Theme.of(context).colorScheme.onPrimary.withAlpha(180)
                        : Colors.grey,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PromptRow extends StatelessWidget {
  final CpmPrompt prompt;
  final List<CpmProject> projects;

  const _PromptRow({required this.prompt, required this.projects});

  String _getProjectName() {
    if (prompt.projectName != null) return prompt.projectName!;
    if (prompt.projectId != null) {
      try {
        return projects.firstWhere((p) => p.id == prompt.projectId).name;
      } catch (_) {}
    }
    return '—';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor.withAlpha(30)),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ID
          SizedBox(
            width: 40,
            child: Text(
              '${prompt.id}',
              style: TextStyle(fontSize: 11, color: Colors.grey[600], fontFamily: 'monospace'),
            ),
          ),
          // Project name
          SizedBox(
            width: 90,
            child: Text(
              _getProjectName(),
              style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          // Prompt content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prompt.content,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  prompt.source,
                  style: TextStyle(fontSize: 10, color: Colors.blue[300]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Date
          Text(
            DateFormat('MM/dd HH:mm').format(prompt.createdAt),
            style: TextStyle(fontSize: 10, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
