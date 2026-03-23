import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../bloc/server_bloc.dart';
import '../bloc/server_event.dart';
import '../models/server_profile.dart';
import '../repository/server_repository.dart';

class ServerEditScreen extends StatefulWidget {
  final String? serverId;

  const ServerEditScreen({super.key, this.serverId});

  @override
  State<ServerEditScreen> createState() => _ServerEditScreenState();
}

class _ServerEditScreenState extends State<ServerEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _hostController = TextEditingController();
  final _portController = TextEditingController(text: '22');
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _initialDirController = TextEditingController();
  final _initCommandController = TextEditingController();
  final _groupController = TextEditingController();

  AuthMethod _authMethod = AuthMethod.password;
  String? _privateKeyContent;
  String? _privateKeyFileName;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    if (widget.serverId != null) {
      _isEditing = true;
      _loadServer();
    }
  }

  Future<void> _loadServer() async {
    final repo = ServerRepository();
    final server = await repo.getById(widget.serverId!);
    if (server != null && mounted) {
      setState(() {
        _nameController.text = server.name;
        _hostController.text = server.host;
        _portController.text = server.port.toString();
        _usernameController.text = server.username;
        _authMethod = server.authMethod;
        _initialDirController.text = server.initialDir ?? '';
        _initCommandController.text = server.initCommand ?? '';
        _groupController.text = server.group ?? '';
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _initialDirController.dispose();
    _initCommandController.dispose();
    _groupController.dispose();
    super.dispose();
  }

  Future<void> _pickKeyFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      setState(() {
        _privateKeyContent = content;
        _privateKeyFileName = result.files.single.name;
      });
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final server = ServerProfile(
      id: widget.serverId ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      host: _hostController.text.trim(),
      port: int.tryParse(_portController.text) ?? 22,
      username: _usernameController.text.trim(),
      authMethod: _authMethod,
      group: _groupController.text.trim().isEmpty ? null : _groupController.text.trim(),
      initialDir: _initialDirController.text.trim().isEmpty ? null : _initialDirController.text.trim(),
      initCommand: _initCommandController.text.trim().isEmpty ? null : _initCommandController.text.trim(),
      createdAt: DateTime.now(),
    );

    if (_isEditing) {
      context.read<ServerBloc>().add(UpdateServer(
            server,
            password: _authMethod == AuthMethod.password ? _passwordController.text : null,
            privateKey: _privateKeyContent,
          ));
    } else {
      context.read<ServerBloc>().add(AddServer(
            server,
            password: _authMethod == AuthMethod.password ? _passwordController.text : null,
            privateKey: _privateKeyContent,
          ));
    }

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Server' : 'Add Server'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Display Name *',
                hintText: 'My Server',
                prefixIcon: Icon(Icons.label),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _hostController,
              decoration: const InputDecoration(
                labelText: 'Host *',
                hintText: '192.168.1.100',
                prefixIcon: Icon(Icons.computer),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username *',
                      hintText: 'root',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _portController,
                    decoration: const InputDecoration(
                      labelText: 'Port',
                      prefixIcon: Icon(Icons.tag),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Authentication', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<AuthMethod>(
              segments: const [
                ButtonSegment(value: AuthMethod.password, label: Text('Password'), icon: Icon(Icons.key)),
                ButtonSegment(value: AuthMethod.privateKey, label: Text('Key File'), icon: Icon(Icons.vpn_key)),
              ],
              selected: {_authMethod},
              onSelectionChanged: (s) => setState(() => _authMethod = s.first),
            ),
            const SizedBox(height: 16),
            if (_authMethod == AuthMethod.password)
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: _pickKeyFile,
                    icon: const Icon(Icons.file_open),
                    label: Text(_privateKeyFileName ?? 'Select Key File'),
                  ),
                  if (_privateKeyFileName != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Selected: $_privateKeyFileName',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 24),
            Text('Optional', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextFormField(
              controller: _groupController,
              decoration: const InputDecoration(
                labelText: 'Group',
                hintText: 'Production',
                prefixIcon: Icon(Icons.folder),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _initialDirController,
              decoration: const InputDecoration(
                labelText: 'Initial Directory',
                hintText: '/home/user/project',
                prefixIcon: Icon(Icons.folder_open),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _initCommandController,
              decoration: const InputDecoration(
                labelText: 'Initial Command',
                hintText: 'conda activate myenv',
                prefixIcon: Icon(Icons.terminal),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
