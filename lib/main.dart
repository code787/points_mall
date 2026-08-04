import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/sync/webdav_sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Auto-sync on startup
  await _autoSync();

  runApp(const ProviderScope(child: PointsMallApp()));
}

Future<void> _autoSync() async {
  try {
    final syncService = WebDAVSyncService();
    final config = await syncService.loadConfig();
    if (config.isConfigured) {
      // Try to acquire lock (will fail if another device is syncing)
      await syncService.startSession(config);
      // Import data from cloud
      await syncService.importData(config);
      await syncService.endSession(config);
    }
  } catch (e) {
    // Ignore auto-sync errors (network issues, lock conflicts, etc.)
  }
}
