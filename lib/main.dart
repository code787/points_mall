import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/local/database_helper.dart';
import 'data/sync/webdav_sync_service.dart';

late final WebDAVSyncService syncService;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  syncService = WebDAVSyncService();
  DatabaseHelper.instance.onDataChanged = syncService.syncNow;
  await _autoSync();

  runApp(const ProviderScope(child: PointsMallApp()));
}

Future<void> _autoSync() async {
  try {
    final config = await syncService.loadConfig();
    if (config.isConfigured) {
      await syncService.startSession(config);
      await syncService.importData(config);
      // Lock stays alive via heartbeat, released when app closes
    }
  } catch (e) {
    // Ignore auto-sync errors
  }
}
