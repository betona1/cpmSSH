import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../bloc/port_forward_bloc.dart';
import '../models/port_forward_model.dart';

class PortForwardAddScreen extends StatefulWidget {
  final PortForwardConfig? editConfig;
  const PortForwardAddScreen({super.key, this.editConfig});

  @override
  State<PortForwardAddScreen> createState() => _PortForwardAddScreenState();
}

class _PortForwardAddScreenState extends State<PortForwardAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtl = TextEditingController();
  final _gwHostCtl = TextEditingController();
  final _gwPortCtl = TextEditingController(text: '10022');
  final _gwUserCtl = TextEditingController();
  final _gwPasswordCtl = TextEditingController();
  final _localPortCtl = TextEditingController();
  final _remoteHostCtl = TextEditingController(text: '192.168.219.100');
  final _remotePortCtl = TextEditingController(text: '22');

  bool _useKeyFile = false;
  bool _allowLan = false;
  String? _keyFileContent;
  String? _keyFileName;
  bool get _isEditing => widget.editConfig != null;

  @override
  void initState() {
    super.initState();
    if (widget.editConfig != null) {
      final c = widget.editConfig!;
      _nameCtl.text = c.name;
      _gwHostCtl.text = c.gatewayHost;
      _gwPortCtl.text = c.gatewayPort.toString();
      _gwUserCtl.text = c.gatewayUsername;
      _localPortCtl.text = c.localPort.toString();
      _remoteHostCtl.text = c.remoteHost;
      _remotePortCtl.text = c.remotePort.toString();
      _allowLan = c.allowLan;
    }
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _gwHostCtl.dispose();
    _gwPortCtl.dispose();
    _gwUserCtl.dispose();
    _gwPasswordCtl.dispose();
    _localPortCtl.dispose();
    _remoteHostCtl.dispose();
    _remotePortCtl.dispose();
    super.dispose();
  }

  Future<void> _pickKey() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null && result.files.single.path != null) {
      final content = await File(result.files.single.path!).readAsString();
      setState(() {
        _keyFileContent = content;
        _keyFileName = result.files.single.name;
      });
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final config = PortForwardConfig(
      id: _isEditing ? widget.editConfig!.id : const Uuid().v4(),
      name: _nameCtl.text.trim(),
      gatewayHost: _gwHostCtl.text.trim(),
      gatewayPort: int.tryParse(_gwPortCtl.text) ?? 22,
      gatewayUsername: _gwUserCtl.text.trim(),
      localPort: int.tryParse(_localPortCtl.text) ?? 0,
      remoteHost: _remoteHostCtl.text.trim(),
      remotePort: int.tryParse(_remotePortCtl.text) ?? 22,
      allowLan: _allowLan,
      createdAt: _isEditing ? widget.editConfig!.createdAt : DateTime.now(),
    );

    if (_isEditing) {
      context.read<PortForwardBloc>().add(PfUpdate(
        config,
        password: _useKeyFile ? null : (_gwPasswordCtl.text.isEmpty ? null : _gwPasswordCtl.text),
        privateKey: _keyFileContent,
      ));
    } else {
      context.read<PortForwardBloc>().add(PfAdd(
        config,
        password: _useKeyFile ? null : _gwPasswordCtl.text,
        privateKey: _keyFileContent,
      ));
    }

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Port Forward' : 'New Port Forward'),
        actions: [
          TextButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Name
            TextFormField(
              controller: _nameCtl,
              decoration: const InputDecoration(
                labelText: 'Name *',
                hintText: 'Office SSH Tunnel',
                prefixIcon: Icon(Icons.label),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 24),

            // Section: Gateway
            _SectionTitle('SSH Gateway (Jump Server)'),
            const SizedBox(height: 8),
            Text(
              'The public server you connect through',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _gwHostCtl,
                    decoration: const InputDecoration(
                      labelText: 'Gateway Host *',
                      hintText: 'my-server.com or IP',
                      prefixIcon: Icon(Icons.public),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _gwPortCtl,
                    decoration: const InputDecoration(labelText: 'Port'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _gwUserCtl,
              decoration: const InputDecoration(
                labelText: 'Username *',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),

            // Auth
            SwitchListTile(
              title: const Text('Use Key File'),
              value: _useKeyFile,
              onChanged: (v) => setState(() => _useKeyFile = v),
            ),
            if (_useKeyFile) ...[
              FilledButton.tonalIcon(
                onPressed: _pickKey,
                icon: const Icon(Icons.file_open),
                label: Text(_keyFileName ?? 'Select Key File'),
              ),
            ] else
              TextFormField(
                controller: _gwPasswordCtl,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              ),
            const SizedBox(height: 24),

            // Section: Forward
            _SectionTitle('Port Forward Rule'),
            const SizedBox(height: 8),

            // Visual diagram
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          const Icon(Icons.computer, size: 32),
                          const SizedBox(height: 4),
                          Text(_allowLan ? 'LAN' : 'Your PC', style: const TextStyle(fontSize: 11)),
                          Text(
                            '${_allowLan ? "0.0.0.0" : "localhost"}:${_localPortCtl.text.isEmpty ? "?" : _localPortCtl.text}',
                            style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.blue),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward, color: Colors.green),
                    Expanded(
                      child: Column(
                        children: [
                          const Icon(Icons.cloud, size: 32),
                          const SizedBox(height: 4),
                          const Text('Gateway', style: TextStyle(fontSize: 11)),
                          Text(
                            _gwHostCtl.text.isEmpty ? '?' : _gwHostCtl.text,
                            style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward, color: Colors.orange),
                    Expanded(
                      child: Column(
                        children: [
                          const Icon(Icons.dns, size: 32),
                          const SizedBox(height: 4),
                          const Text('Target', style: TextStyle(fontSize: 11)),
                          Text(
                            '${_remoteHostCtl.text.isEmpty ? "?" : _remoteHostCtl.text}:${_remotePortCtl.text}',
                            style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.orange),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            SwitchListTile(
              title: const Text('Allow LAN Access'),
              subtitle: Text(
                _allowLan
                    ? 'Bind 0.0.0.0 — accessible from other devices on the network'
                    : 'Bind localhost — only this device',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              secondary: Icon(_allowLan ? Icons.lan : Icons.computer),
              value: _allowLan,
              onChanged: (v) => setState(() => _allowLan = v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _localPortCtl,
              decoration: const InputDecoration(
                labelText: 'Local Port *',
                hintText: '2222',
                prefixIcon: Icon(Icons.input),
                helperText: 'Port on your PC to listen on',
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                final port = int.tryParse(v);
                if (port == null || port < 1 || port > 65535) return 'Invalid port';
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _remoteHostCtl,
                    decoration: const InputDecoration(
                      labelText: 'Remote Host *',
                      hintText: '192.168.219.100',
                      prefixIcon: Icon(Icons.dns),
                      helperText: 'Target server (behind gateway)',
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _remotePortCtl,
                    decoration: const InputDecoration(labelText: 'Port'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Summary', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Text(
                      'ssh'
                      '${_gwPortCtl.text != "22" ? " -p ${_gwPortCtl.text}" : ""}'
                      ' -L ${_localPortCtl.text.isEmpty ? "?" : _localPortCtl.text}'
                      ':${_remoteHostCtl.text.isEmpty ? "?" : _remoteHostCtl.text}'
                      ':${_remotePortCtl.text.isEmpty ? "?" : _remotePortCtl.text}'
                      ' ${_gwUserCtl.text.isEmpty ? "?" : _gwUserCtl.text}'
                      '@${_gwHostCtl.text.isEmpty ? "?" : _gwHostCtl.text}',
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
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
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
    );
  }
}
