import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../main.dart' show syncService;
import '../../providers/auth_provider.dart';

class SyncLockState {
  final bool isLockedByOther;
  final int remainingMinutes;
  final bool isNetworkError;

  const SyncLockState({
    this.isLockedByOther = false,
    this.remainingMinutes = 0,
    this.isNetworkError = false,
  });
}

class SyncLockMonitor extends StateNotifier<SyncLockState> {
  SyncLockMonitor({this.onLockReleased}) : super(const SyncLockState()) {
    _startMonitor();
  }

  final Future<void> Function()? onLockReleased;

  Timer? _monitorTimer;
  bool _wasLockedByOther = false;

  void _startMonitor() {
    _checkLockStatus();
    _monitorTimer = Timer.periodic(const Duration(minutes: 1), (_) => _checkLockStatus());
  }

  Future<void> _checkLockStatus() async {
    try {
      final config = await syncService.loadConfig();
      if (!config.isConfigured) {
        state = const SyncLockState();
        return;
      }

      final lock = await syncService.checkLock(config);
      final myDeviceId = await syncService.getDeviceId();

      if (lock == null) {
        if (_wasLockedByOther) {
          _wasLockedByOther = false;
          await _autoDownloadOnExpiry();
        }
        state = const SyncLockState();
      } else if (lock.deviceId == myDeviceId) {
        _wasLockedByOther = false;
        state = const SyncLockState();
      } else {
        _wasLockedByOther = true;
        state = SyncLockState(
          isLockedByOther: true,
          remainingMinutes: int.parse(syncService.remainingMinutes(lock)),
        );
      }
    } catch (e) {
      state = const SyncLockState(isLockedByOther: true, isNetworkError: true);
    }
  }

  Future<void> _autoDownloadOnExpiry() async {
    try {
      final config = await syncService.loadConfig();
      if (!config.isConfigured) return;
      await syncService.importData(config);
      await onLockReleased?.call();
    } catch (e) {
      // Ignore auto-sync errors
    }
  }

  @override
  void dispose() {
    _monitorTimer?.cancel();
    super.dispose();
  }
}

final syncLockProvider = StateNotifierProvider<SyncLockMonitor, SyncLockState>((ref) {
  return SyncLockMonitor(
    onLockReleased: () => ref.read(authControllerProvider).refreshUser(),
  );
});

class ReadOnlyBanner extends StatelessWidget {
  final int remainingMinutes;
  final bool isNetworkError;

  const ReadOnlyBanner({
    super.key,
    this.remainingMinutes = 0,
    this.isNetworkError = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isNetworkError
        ? const Color(0xFFE53935).withValues(alpha: 0.1)
        : const Color(0xFFFF9800).withValues(alpha: 0.1);
    final iconColor = isNetworkError
        ? const Color(0xFFE53935)
        : const Color(0xFFFF9800);
    final textColor = isNetworkError
        ? const Color(0xFFE53935)
        : const Color(0xFFFF6D00);
    final icon = isNetworkError ? Icons.wifi_off_outlined : Icons.lock_outline;
    final text = isNetworkError
        ? '网络异常，当前为只读模式'
        : '其他设备正在同步，当前为只读模式（约$remainingMinutes分钟）';

    return Container(
      width: double.infinity,
      color: color,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
