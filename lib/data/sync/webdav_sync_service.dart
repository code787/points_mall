import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
  static const _syncFolder = 'points_mall_sync';
  static const _syncFile = 'mall_data.json';

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

  String _normalizeUrl(String url) => url.endsWith('/') ? url : '$url/';

  Map<String, String> _authHeaders(WebDAVConfig config) {
    final credentials = base64Encode(utf8.encode('${config.username}:${config.password}'));
    return {
      'Authorization': 'Basic $credentials',
      'Content-Type': 'application/json; charset=utf-8',
    };
  }

  Future<String?> testConnection(WebDAVConfig config) async {
    try {
      final url = Uri.parse(_normalizeUrl(config.url));
      final headers = Map<String, String>.from(_authHeaders(config))..['Depth'] = '0';
      final request = http.Request('PROPFIND', url)..headers.addAll(headers);
      final response = await request.send().timeout(const Duration(seconds: 15));
      final body = await response.stream.bytesToString();
      if (response.statusCode == 401) return '用户名或密码错误';
      if (response.statusCode == 200 || response.statusCode == 207) return null;
      if (body.contains('OperationNotAllowed')) return 'WebDAV 未开启';
      return 'HTTP ${response.statusCode}';
    } catch (e) {
      return e.toString();
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
    final body = utf8.encode(json);

    final baseUrl = _normalizeUrl(config.url);
    final folderUrl = Uri.parse('$baseUrl$_syncFolder/');
    final fileUrl = Uri.parse('$baseUrl$_syncFolder/$_syncFile');
    final headers = _authHeaders(config);

    final mkRequest = http.Request('MKCOL', folderUrl)..headers.addAll(headers);
    final mkResponse = await mkRequest.send();
    await mkResponse.stream.drain();

    final putResponse = await http.put(fileUrl, headers: headers, body: body).timeout(const Duration(seconds: 30));
    if (putResponse.statusCode != 200 && putResponse.statusCode != 201 && putResponse.statusCode != 204) {
      throw Exception('上传失败: HTTP ${putResponse.statusCode}');
    }

    await _updateLastSyncTime();
  }

  Future<void> importData(WebDAVConfig config) async {
    if (!config.isConfigured) throw Exception('请先配置坚果云账号');

    final fileUrl = Uri.parse('${_normalizeUrl(config.url)}$_syncFolder/$_syncFile');
    final response = await http.get(fileUrl, headers: _authHeaders(config)).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('下载失败: HTTP ${response.statusCode}');
    }

    final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
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

    await _updateLastSyncTime();
  }
}
