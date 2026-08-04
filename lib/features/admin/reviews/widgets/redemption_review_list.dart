import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../data/models/redemption_request.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/feature_providers.dart';
import '../../../../providers/repository_providers.dart';
import '../../../../widgets/confirm_dialog.dart';
import '../../../../data/sync/sync_lock_monitor.dart';
import '../../../../widgets/empty_state.dart';
import '../../../../widgets/item_avatar.dart';

class RedemptionReviewList extends ConsumerWidget {
  const RedemptionReviewList({super.key});

  Future<void> _handle(WidgetRef ref, RedemptionRequest req, bool approve) async {
    final admin = ref.read(currentUserProvider);
    if (admin == null) return;
    try {
      if (approve) {
        final ok = await confirmDialog(
          ref.context,
          title: '通过兑换',
          message: '确认通过「${req.itemName}」x${req.quantity} 的兑换申请？\n'
              '通过后将扣除 ${req.userName} ${req.totalCost} 积分并扣减库存。',
          confirmText: '通过',
          confirmColor: const Color(0xFF43A047),
        );
        if (!ok) return;
        await ref.read(redemptionRepoProvider).approve(req.id, admin.id);
      } else {
        final reason = await promptDialog(
          ref.context,
          title: '驳回申请',
          hint: '填写驳回原因（可选）',
          confirmText: '驳回',
        );
        if (reason == null) return;
        await ref.read(redemptionRepoProvider).reject(req.id, admin.id, reason: reason);
      }
      if (ref.context.mounted) showSnack(ref.context, approve ? '已通过' : '已驳回');
    } on Exception catch (e) {
      if (ref.context.mounted) showSnack(ref.context, e.toString(), isError: true);
    } finally {
      ref.invalidate(pendingRedemptionsProvider);
      ref.invalidate(statsProvider);
      ref.invalidate(usersProvider);
      ref.invalidate(itemsProvider);
      ref.invalidate(allRedemptionRequestsProvider);
      ref.invalidate(allPointsTransactionsProvider);
      ref.invalidate(userRedemptionRequestsProvider(req.userId));
      ref.invalidate(userPointsTransactionsProvider(req.userId));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final listAsync = ref.watch(pendingRedemptionsProvider);
    final lockState = ref.watch(syncLockProvider);

    return listAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(icon: Icons.error_outline, title: '加载失败', subtitle: '$e'),
      data: (list) {
        if (list.isEmpty) {
          return const EmptyState(
            icon: Icons.fact_check_outlined,
            title: '暂无待审兑换申请',
            subtitle: '下拉刷新或点击右上角刷新',
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(pendingRedemptionsProvider);
            await ref.read(pendingRedemptionsProvider.future);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final req = list[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            ItemAvatar(emoji: req.itemEmoji ?? '🎁', color: req.itemColor ?? 0xFF1E88E5, size: 48),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    req.itemName ?? '物品',
                                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${req.userName ?? '用户#${req.userId}'} · x${req.quantity}',
                                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.stars, size: 15, color: theme.colorScheme.primary),
                                    const SizedBox(width: 3),
                                    Text(
                                      '${req.totalCost}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  formatDateTime(req.createdAt),
                                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (req.note != null && req.note!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(req.note!, style: theme.textTheme.bodyMedium),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: lockState.isLockedByOther
                                    ? null
                                    : () => _handle(ref, req, false),
                                icon: const Icon(Icons.close),
                                label: const Text('驳回'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: theme.colorScheme.error,
                                  minimumSize: const Size.fromHeight(42),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: lockState.isLockedByOther
                                    ? null
                                    : () => _handle(ref, req, true),
                                icon: const Icon(Icons.check),
                                label: const Text('通过'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF43A047),
                                  minimumSize: const Size.fromHeight(42),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
