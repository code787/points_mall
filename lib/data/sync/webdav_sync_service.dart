import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;

import '../local/database_helper.dart';

class WebDAVConfig {
  final String url;
  final String username;
  final String password;

  const WebDAVConfig({
    required this.url,
    required this.username,
    required this.password,
  });

  bool get isConfigured => url.isNotEmpty && username.isNotEmpty && password.isNotEmpty;
}

class WebDAVSyncService {
  static const _keyUrl = 'webdav_url';
  static const _keyUsername = 'webdav_username';
  static const _keyPassword = 'webdav_password';
  static const _keyLastSync = 'webdav_last_sync';
  static const _syncFolder = '/points_mall_sync';
  static const _syncFile = '/points_mall_sync/mall_data.json';

  Future<WebDAVConfig> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    return WebDAVConfig(
      url: prefs.getString(_keyUrl) ?? '',
      username: prefs.getString(_keyUsername) ?? '',
      password: prefs.getString(_keyPassword) ?? '',
    );
  }

  Future<void> saveConfig(WebDAVConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUrl, config.url);
    await prefs.setString(_keyUsername, config.username);
    await prefs.setString(_keyPassword, config.password);
  }

  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_keyLastSync);
    return ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  }

  Future<void> _updateLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLastSync, DateTime.now().millisecondsSinceEpoch);
  }

  webdav.Client _createClient(WebDAVConfig config) {
    final client = webdav.newClient(
      config.url,
      user: config.username,
      password: config.password,
    );
    client.setConnectTimeout(30000);
    return client;
  }

  Future<bool> testConnection(WebDAVConfig config) async {
    try {
      final client = _createClient(config);
      await client.ping();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> exportData(WebDAVConfig config) async {
    if (!config.isConfigured) throw Exception('请先配置坚果云账号');

    final db = await DatabaseHelper.instance.database;
    final data = <String, dynamic>{};

    data['users'] = await db.query('users');
    data['items'] = await db.query('items');
    data['points_transactions'] = await db.query('points_transactions');
    data['redemption_requests'] = await db.query('redemption_requests');

    final json = jsonEncode(data);

    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/mall_data_sync.json');
    await tempFile.writeAsString(json);

    final client = _createClient(config);
    await client.mkdir(_syncFolder);
    await client.writeFromFile(
      _syncFile,
      tempFile.path,
    );

    await tempFile.delete();
    await _updateLastSyncTime();
  }

  Future<void> importData(WebDAVConfig config) async {
    if (!config.isConfigured) throw Exception('请先配置坚果云账号');

    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/mall_data_sync.json');

    final client = _createClient(config);
    await client.read2File(_syncFile, tempFile.path);

    final jsonStr = await tempFile.readAsString();
    final json = jsonDecode(jsonStr) as Map<String, dynamic>;

    final db = await DatabaseHelper.instance.database;

    await db.transaction((txn) async {
      await txn.delete('users');
      await txn.delete('items');
      await txn.delete('points_transactions');
      await txn.delete('redemption_requests');

      for (final row in (json['users'] as List)) {
        await txn.insert('users', Map<String, Object?>.from(row));
      }
      for (final row in (json['items'] as List)) {
        await txn.insert('items', Map<String, Object?>.from(row));
      }
      for (final row in (json['points_transactions'] as List)) {
        await txn.insert('points_transactions', Map<String, Object?>.from(row));
      }
      for (final row in (json['redemption_requests'] as List)) {
        await txn.insert('redemption_requests', Map<String, Object?>.from(row));
      }
    });

    await tempFile.delete();
    await _updateLastSyncTime();
  }

  Future<void> fullSync(WebDAVConfig config) async {
    if (!config.isConfigured) throw Exception('请先配置坚果云账号');

    final client = _createClient(config);
    try {
      final items = await client.readDir(_syncFolder);
      if (items.isNotEmpty) {
        await importData(config);
        return;
      }
    } catch (_) {}

    await exportData(config);
  }
}
