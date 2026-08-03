import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/models/redemption_request.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/feature_providers.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/item_avatar.dart';
import '../../../widgets/status_badge.dart';

class MyOrdersScreen extends ConsumerWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final ordersAsync = ref.watch(userRedemptionRequestsProvider(user?.id ?? -1));

    return Scaffold(
      appBar: AppBar(title: const Text('兑换记录')),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(icon: Icons.error_outline, title: '加载失败', subtitle: '$e'),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.local_activity_outlined,
              title: '暂无兑换记录',
              subtitle: '去商城挑选心仪物品吧',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _OrderCard(req: list[index]),
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.req});
  final RedemptionRequest req;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
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
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'x${req.quantity}',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                      ),
                    ],
                  ),
                ),
                ReviewStatusBadge(status: req.status),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatDateTime(req.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                ),
                Row(
                  children: [
                    Icon(Icons.stars, size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      '${req.totalCost}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (req.note != null && req.note!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                req.note!,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
