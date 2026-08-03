import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../data/models/enums.dart';
import '../../../../data/models/points_transaction.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/feature_providers.dart';
import '../../../../providers/repository_providers.dart';
import '../../../../widgets/confirm_dialog.dart';
import '../../../../widgets/empty_state.dart';

class PointsReviewList extends ConsumerWidget {
  const PointsReviewList({super.key});

  Future<void> _handle(WidgetRef ref, PointsTransaction tx, bool approve) async {
    final admin = ref.read(currentUserProvider);
    if (admin == null) return;
    try {
      if (approve) {
        final ok = await confirmDialog(
          ref.context,
          title: '通过审核',
          message: '确认通过 ${tx.userName ?? '用户'} 的 ${formatPointsPlain(tx.amount)} 积分记录？通过后将立即生效。',
          confirmText: '通过',
          confirmColor: const Color(0xFF43A047),
        );
        if (!ok) return;
        await ref.read(pointsRepoProvider).approve(tx.id, admin.id);
      } else {
        final reason = await promptDialog(
          ref.context,
          title: '驳回申请',
          hint: '填写驳回原因（可选）',
          confirmText: '驳回',
        );
        if (reason == null) return;
        await ref.read(pointsRepoProvider).reject(tx.id, admin.id, reason: reason);
      }
      if (ref.context.mounted) showSnack(ref.context, approve ? '已通过' : '已驳回');
    } on Exception catch (e) {
      if (ref.context.mounted) showSnack(ref.context, e.toString(), isError: true);
    } finally {
      ref.invalidate(pendingPointsProvider);
      ref.invalidate(statsProvider);
      ref.invalidate(usersProvider);
      ref.invalidate(allPointsTransactionsProvider);
      ref.invalidate(userPointsTransactionsProvider(tx.userId));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final listAsync = ref.watch(pendingPointsProvider);

    return listAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(icon: Icons.error_outline, title: '加载失败', subtitle: '$e'),
      data: (list) {
        if (list.isEmpty) {
          return const EmptyState(
            icon: Icons.fact_check_outlined,
            title: '暂无待审积分记录',
            subtitle: '下拉刷新或点击右上角刷新',
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(pendingPointsProvider);
            await ref.read(pendingPointsProvider.future);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final tx = list[index];
              final isNegative = tx.amount < 0;
              final color = isNegative ? theme.colorScheme.error : theme.colorScheme.primary;
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
                            Expanded(
                              child: Text(
                                tx.userName ?? '用户#${tx.userId}',
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Text(
                              formatPoints(tx.amount),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              tx.type.label,
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              formatDateTime(tx.createdAt),
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                            ),
                          ],
                        ),
                        if (tx.note != null && tx.note!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(tx.note!, style: theme.textTheme.bodyMedium),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _handle(ref, tx, false),
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
                                onPressed: () => _handle(ref, tx, true),
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
