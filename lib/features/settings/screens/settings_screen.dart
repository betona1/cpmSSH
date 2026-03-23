import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../../../core/constants.dart';
import '../../../core/theme/theme_provider.dart';
import '../../cpm/bloc/cpm_bloc.dart';
import '../../cpm/bloc/cpm_event.dart';
import '../../cpm/bloc/cpm_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _cpmUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCpmUrl();
  }

  Future<void> _loadCpmUrl() async {
    final prefs = await SharedPreferences.getInstance();
    _cpmUrlController.text = prefs.getString('cpm_base_url') ?? CpmConfig.baseUrl;
  }

  Future<void> _saveCpmUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final url = _cpmUrlController.text.trim();
    await prefs.setString('cpm_base_url', url);
    if (mounted) {
      context.read<CpmBloc>().add(CpmUpdateBaseUrl(url));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CPM URL saved')));
    }
  }

  @override
  void dispose() {
    _cpmUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tp = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // ─── Theme ───
          _Section('Appearance'),
          ListTile(
            title: const Text('Theme'),
            trailing: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode, size: 16)),
                ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode, size: 16)),
              ],
              selected: {tp.mode},
              onSelectionChanged: (s) => tp.toggleTheme(),
            ),
          ),
          const Divider(),

          // ─── Terminal Font ───
          _Section('Terminal'),
          ListTile(
            title: const Text('Font'),
            subtitle: Text(tp.fontFamily, style: TextStyle(fontFamily: tp.fontFamily)),
            trailing: DropdownButton<String>(
              value: ThemeProvider.availableFonts.contains(tp.fontFamily) ? tp.fontFamily : ThemeProvider.availableFonts.first,
              items: ThemeProvider.availableFonts.map((f) => DropdownMenuItem(
                value: f,
                child: Text(f, style: TextStyle(fontFamily: f, fontSize: 13)),
              )).toList(),
              onChanged: (v) { if (v != null) tp.setFontFamily(v); },
            ),
          ),
          ListTile(
            title: const Text('Font Size'),
            subtitle: Slider(
              value: tp.fontSize,
              min: 10,
              max: 24,
              divisions: 14,
              label: tp.fontSize.toStringAsFixed(0),
              onChanged: (v) => tp.setFontSize(v),
            ),
            trailing: Text('${tp.fontSize.toStringAsFixed(0)}px'),
          ),
          // Preview
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF272822),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'user@server:~\$ echo "Hello 한글 테스트"\nHello 한글 테스트\n┌──────────────┐\n│  Box Drawing  │\n└──────────────┘',
              style: TextStyle(
                fontFamily: tp.fontFamily,
                fontSize: tp.fontSize,
                color: const Color(0xFFF8F8F2),
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(),

          // ─── SSH Defaults ───
          _Section('SSH Defaults'),
          ListTile(
            title: const Text('Default Port'),
            trailing: SizedBox(
              width: 80,
              child: TextField(
                controller: TextEditingController(text: '${tp.defaultPort}'),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                onSubmitted: (v) {
                  final port = int.tryParse(v);
                  if (port != null && port > 0 && port <= 65535) tp.setDefaultPort(port);
                },
              ),
            ),
          ),
          ListTile(
            title: const Text('Keep-alive Interval'),
            trailing: DropdownButton<int>(
              value: tp.keepAliveSeconds,
              items: [10, 15, 20, 30, 60].map((s) => DropdownMenuItem(value: s, child: Text('${s}s'))).toList(),
              onChanged: (v) { if (v != null) tp.setKeepAlive(v); },
            ),
          ),
          ListTile(
            title: const Text('Connection Timeout'),
            trailing: DropdownButton<int>(
              value: tp.connectTimeoutSeconds,
              items: [5, 10, 15, 20, 30].map((s) => DropdownMenuItem(value: s, child: Text('${s}s'))).toList(),
              onChanged: (v) { if (v != null) tp.setConnectTimeout(v); },
            ),
          ),
          const Divider(),

          // ─── CPM Server ───
          _Section('CPM Server'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cpmUrlController,
                    decoration: const InputDecoration(labelText: 'CPM Server URL', hintText: 'http://localhost:9200'),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _saveCpmUrl, child: const Text('Save')),
              ],
            ),
          ),
          BlocBuilder<CpmBloc, CpmState>(
            builder: (context, state) => ListTile(
              leading: Icon(state.isConnected ? Icons.check_circle : Icons.error, color: state.isConnected ? Colors.green : Colors.red),
              title: Text(state.isConnected ? 'Connected' : 'Not Connected'),
              trailing: TextButton(onPressed: () => context.read<CpmBloc>().add(CpmCheckConnection()), child: const Text('Test')),
            ),
          ),
          const Divider(),

          // ─── About ───
          _Section('About'),
          const ListTile(title: Text('Version'), trailing: Text(AppConstants.appVersion)),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  const _Section(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
    );
  }
}
