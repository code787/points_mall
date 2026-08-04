import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

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

class SyncLock {
  final String deviceId;
  final int timestamp;

  const SyncLock({required this.deviceId, required this.timestamp});

  bool get isExpired => DateTime.now().millisecondsSinceEpoch - timestamp > 5 * 60 * 1000;

  factory SyncLock.fromJson(String json) {
    final map = jsonDecode(json);
    return SyncLock(deviceId: map['device_id'], timestamp: map['timestamp']);
  }

  String toJson() => jsonEncode({'device_id': deviceId, 'timestamp': timestamp});
}

class WebDAVSyncService {
  static const _keyUrl = 'webdav_url';
  static const _keyUsername = 'webdav_username';
  static const _keyPassword = 'webdav_password';
  static const _keyLastSync = 'webdav_last_sync';
  static const _keyDeviceId = 'webdav_device_id';
  static const _syncFolder = 'points_mall_sync';
  static const _syncFile = 'points_mall.db';
  static const _lockFile = 'points_mall.lock';
  static const _heartbeatInterval = Duration(minutes: 1);
  static const _lockTimeout = Duration(minutes: 5);

  Timer? _heartbeatTimer;
  String? _currentDeviceId;

  Future<String> getDeviceId() async {
    if (_currentDeviceId != null) return _currentDeviceId!;
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_keyDeviceId);
    if (id == null) {
      id = const Uuid().v4();
      await prefs.setString(_keyDeviceId, id);
    }
    _currentDeviceId = id;
    return id;
  }

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
    return {'Authorization': 'Basic $credentials'};
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

  Future<SyncLock?> checkLock(WebDAVConfig config) async {
    try {
      final url = Uri.parse('${_normalizeUrl(config.url)}$_syncFolder/$_lockFile');
      final response = await http.get(url, headers: _authHeaders(config)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final lock = SyncLock.fromJson(utf8.decode(response.bodyBytes));
        if (lock.isExpired) return null;
        return lock;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  String remainingMinutes(SyncLock lock) {
    final elapsed = DateTime.now().millisecondsSinceEpoch - lock.timestamp;
    final remaining = _lockTimeout.inMilliseconds - elapsed;
    return (remaining / 60000).ceil().toString();
  }

  Future<void> _acquireLock(WebDAVConfig config) async {
    final deviceId = await getDeviceId();
    final lock = SyncLock(deviceId: deviceId, timestamp: DateTime.now().millisecondsSinceEpoch);
    final url = Uri.parse('${_normalizeUrl(config.url)}$_syncFolder/$_lockFile');
    final headers = Map<String, String>.from(_authHeaders(config))
      ..['Content-Type'] = 'application/json; charset=utf-8';
    await http.put(url, headers: headers, body: utf8.encode(lock.toJson())).timeout(const Duration(seconds: 10));
  }

  Future<void> _updateLock(WebDAVConfig config) async {
    final deviceId = await getDeviceId();
    final lock = SyncLock(deviceId: deviceId, timestamp: DateTime.now().millisecondsSinceEpoch);
    final url = Uri.parse('${_normalizeUrl(config.url)}$_syncFolder/$_lockFile');
    final headers = Map<String, String>.from(_authHeaders(config))
      ..['Content-Type'] = 'application/json; charset=utf-8';
    await http.put(url, headers: headers, body: utf8.encode(lock.toJson())).timeout(const Duration(seconds: 10));
  }

  Future<void> _releaseLock(WebDAVConfig config) async {
    try {
      final deviceId = await getDeviceId();
      final existing = await checkLock(config);
      if (existing != null && existing.deviceId == deviceId) {
        final url = Uri.parse('${_normalizeUrl(config.url)}$_syncFolder/$_lockFile');
        await http.delete(url, headers: _authHeaders(config)).timeout(const Duration(seconds: 10));
      }
    } catch (e) {
      // ignore lock release errors
    }
  }

  void _startHeartbeat(WebDAVConfig config) {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) => _updateLock(config));
  }

  void stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  Future<void> startSession(WebDAVConfig config) async {
    if (!config.isConfigured) return;
    final lock = await checkLock(config);
    if (lock != null) {
      throw Exception('其他设备正在同步，请${_remainingMinutes(lock)}分钟后再试');
    }
    await _acquireLock(config);
    _startHeartbeat(config);
  }

  Future<void> endSession(WebDAVConfig config) async {
    stopHeartbeat();
    await _releaseLock(config);
  }

  String _remainingMinutes(SyncLock lock) {
    final elapsed = DateTime.now().millisecondsSinceEpoch - lock.timestamp;
    final remaining = _lockTimeout.inMilliseconds - elapsed;
    return (remaining / 60000).ceil().toString();
  }

  Future<void> ensureFolder(WebDAVConfig config) async {
    final baseUrl = _normalizeUrl(config.url);
    final folderUrl = Uri.parse('$baseUrl$_syncFolder/');
    final mkRequest = http.Request('MKCOL', folderUrl)..headers.addAll(_authHeaders(config));
    final mkResponse = await mkRequest.send();
    await mkResponse.stream.drain();
  }

  Future<void> exportData(WebDAVConfig config) async {
    if (!config.isConfigured) throw Exception('请先配置坚果云账号');

    final dbHelper = DatabaseHelper.instance;
    await dbHelper.close();

    final dbPath = await dbHelper.dbPath;
    final dbFile = File(dbPath);
    if (!await dbFile.exists()) throw Exception('数据库文件不存在');

    final body = await dbFile.readAsBytes();

    final baseUrl = _normalizeUrl(config.url);
    final fileUrl = Uri.parse('$baseUrl$_syncFolder/$_syncFile');
    final headers = Map<String, String>.from(_authHeaders(config))
      ..['Content-Type'] = 'application/octet-stream';

    await ensureFolder(config);

    final putResponse = await http.put(fileUrl, headers: headers, body: body).timeout(const Duration(seconds: 60));
    if (putResponse.statusCode != 200 && putResponse.statusCode != 201 && putResponse.statusCode != 204) {
      throw Exception('上传失败: HTTP ${putResponse.statusCode}');
    }

    await _updateLastSyncTime();
  }

  Future<void> importData(WebDAVConfig config) async {
    if (!config.isConfigured) throw Exception('请先配置坚果云账号');

    final fileUrl = Uri.parse('${_normalizeUrl(config.url)}$_syncFolder/$_syncFile');
    final headers = Map<String, String>.from(_authHeaders(config));
    final response = await http.get(fileUrl, headers: headers).timeout(const Duration(seconds: 60));

    if (response.statusCode != 200) {
      throw Exception('下载失败: HTTP ${response.statusCode}');
    }

    final dbHelper = DatabaseHelper.instance;
    await dbHelper.close();

    final dbPath = await dbHelper.dbPath;
    final dbFile = File(dbPath);
    await dbFile.writeAsBytes(response.bodyBytes);

    await _updateLastSyncTime();
  }

  Future<void> syncNow() async {
    try {
      final config = await loadConfig();
      if (!config.isConfigured) return;
      await exportData(config);
    } catch (e) {
      // Ignore sync errors
    }
  }

  void dispose() {
    stopHeartbeat();
  }
}
