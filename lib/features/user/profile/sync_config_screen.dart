import 'package:flutter/material.dart';

import '../../../data/sync/webdav_sync_service.dart';
import '../../../widgets/confirm_dialog.dart';

class SyncConfigScreen extends StatefulWidget {
  const SyncConfigScreen({super.key});

  @override
  State<SyncConfigScreen> createState() => _SyncConfigScreenState();
}

class _SyncConfigScreenState extends State<SyncConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _syncService = WebDAVSyncService();
  bool _loading = false;
  bool _testing = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final config = await _syncService.loadConfig();
    setState(() {
      _urlController.text = config.url;
      _usernameController.text = config.username;
      _passwordController.text = config.password;
    });
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _testing = true);
    try {
      final config = WebDAVConfig(
        url: _urlController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
      );
      final ok = await _syncService.testConnection(config);
      if (mounted) {
        showSnack(context, ok ? '连接成功' : '连接失败，请检查配置', isError: !ok);
      }
    } catch (e) {
      if (mounted) showSnack(context, '测试失败: $e', isError: true);
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final config = WebDAVConfig(
        url: _urlController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
      );
      await _syncService.saveConfig(config);
      if (mounted) {
        showSnack(context, '配置已保存');
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) showSnack(context, '保存失败: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('坚果云配置')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('WebDAV 设置', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      '请在坚果云「账号信息 → 安全选项 → 第三方应用管理」中生成应用密码',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _urlController,
                      decoration: const InputDecoration(
                        labelText: 'WebDAV 地址',
                        hintText: 'https://dav.jianguoyun.com/dav/',
                        prefixIcon: Icon(Icons.link),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? '请输入地址' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: '用户名（邮箱）',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? '请输入用户名' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: '应用密码',
                        hintText: '非登录密码，需在坚果云生成',
                        prefixIcon: Icon(Icons.vpn_key_outlined),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? '请输入应用密码' : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _testing ? null : _testConnection,
                    icon: _testing
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.wifi_find),
                    label: const Text('测试连接'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _loading ? null : _save,
                    icon: _loading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.save),
                    label: const Text('保存配置'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
