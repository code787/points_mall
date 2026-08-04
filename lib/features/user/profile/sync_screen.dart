import 'package:flutter/material.dart';

import '../../../data/sync/webdav_sync_service.dart';
import '../../../widgets/confirm_dialog.dart';
import 'sync_config_screen.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  final _syncService = WebDAVSyncService();
  WebDAVConfig? _config;
  DateTime? _lastSync;
  bool _syncing = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  @override
  void dispose() {
    _syncService.dispose();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    final config = await _syncService.loadConfig();
    final lastSync = await _syncService.getLastSyncTime();
    setState(() {
      _config = config;
      _lastSync = lastSync;
    });
  }

  Future<void> _export() async {
    if (_config == null || !_config!.isConfigured) {
      await _openConfig();
      return;
    }

    // Check lock
    final lock = await _syncService.checkLock(_config!);
    if (lock != null) {
      if (mounted) {
        final remaining = _syncService.remainingMinutes(lock);
        showSnack(context, '其他设备正在同步，请$remaining分钟后再试', isError: true);
      }
      return;
    }

    if (!mounted) return;
    final ok = await confirmDialog(
      context,
      title: '上传数据',
      message: '将本地数据上传到坚果云？\n这会覆盖云端的现有数据。',
      confirmText: '上传',
    );
    if (!ok) return;

    setState(() {
      _syncing = true;
      _status = '正在上传...';
    });
    try {
      await _syncService.exportData(_config!);
      await _loadStatus();
      if (mounted) showSnack(context, '上传成功');
    } catch (e) {
      if (mounted) showSnack(context, '上传失败: $e', isError: true);
    } finally {
      if (mounted) setState(() { _syncing = false; _status = null; });
    }
  }

  Future<void> _import() async {
    if (_config == null || !_config!.isConfigured) {
      await _openConfig();
      return;
    }

    // Check lock
    final lock = await _syncService.checkLock(_config!);
    if (lock != null) {
      if (mounted) {
        final remaining = _syncService.remainingMinutes(lock);
        showSnack(context, '其他设备正在同步，请$remaining分钟后再试', isError: true);
      }
      return;
    }

    if (!mounted) return;
    final ok = await confirmDialog(
      context,
      title: '下载数据',
      message: '从坚果云下载数据？\n这会覆盖本地的现有数据。',
      confirmText: '下载',
    );
    if (!ok) return;

    setState(() {
      _syncing = true;
      _status = '正在下载...';
    });
    try {
      await _syncService.importData(_config!);
      await _loadStatus();
      if (mounted) showSnack(context, '下载成功');
    } catch (e) {
      if (mounted) showSnack(context, '下载失败: $e', isError: true);
    } finally {
      if (mounted) setState(() { _syncing = false; _status = null; });
    }
  }

  Future<void> _openConfig() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const SyncConfigScreen()),
    );
    if (result == true) await _loadStatus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final configured = _config?.isConfigured ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('数据同步')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.cloud_outlined, color: configured ? theme.colorScheme.primary : theme.colorScheme.outline),
                      const SizedBox(width: 8),
                      Text('坚果云', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: configured
                              ? theme.colorScheme.primaryContainer
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          configured ? '已配置' : '未配置',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: configured
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_lastSync != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '上次同步: ${_lastSync!.year}-${_lastSync!.month.toString().padLeft(2, '0')}-${_lastSync!.day.toString().padLeft(2, '0')} ${_lastSync!.hour.toString().padLeft(2, '0')}:${_lastSync!.minute.toString().padLeft(2, '0')}',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_syncing)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(width: 16),
                    Text(_status ?? '同步中...'),
                  ],
                ),
              ),
            ),
          if (!_syncing) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: configured ? _export : _openConfig,
                icon: const Icon(Icons.cloud_upload_outlined),
                label: Text(configured ? '上传到坚果云' : '配置坚果云'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: configured ? _import : null,
                icon: const Icon(Icons.cloud_download_outlined),
                label: const Text('从坚果云下载'),
              ),
            ),
            if (configured) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _openConfig,
                  icon: const Icon(Icons.settings_outlined),
                  label: const Text('修改配置'),
                ),
              ),
            ],
          ],
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('使用说明', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    '1. 打开坚果云网页版 → 账号信息 → 安全选项\n'
                    '2. 第三方应用管理 → 添加应用密码\n'
                    '3. 复制应用密码填入上方配置\n'
                    '4. 上传：将本地数据同步到云端\n'
                    '5. 下载：从云端同步数据到本地\n\n'
                    '首次使用请先配置，然后上传初始化数据',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
