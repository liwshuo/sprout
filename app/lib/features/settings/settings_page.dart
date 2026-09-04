import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/shared_prefs_provider.dart';

/// 设置：LLM API Key（供周报生成）等本地配置。
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _keyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(sharedPreferencesProvider);
    _keyCtrl.text = prefs.getString('llm_api_key') ?? '';
  }

  @override
  void dispose() {
    _keyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _keyCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'LLM API Key（周报生成用）',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                await ref
                    .read(sharedPreferencesProvider)
                    .setString('llm_api_key', _keyCtrl.text.trim());
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('已保存')));
                }
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }
}
