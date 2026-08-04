import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/points_transaction.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/feature_providers.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/status_badge.dart';
import 'points_application_screen.dart';

class MyPointsScreen extends ConsumerWidget {
  const MyPointsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final txAsync = ref.watch(userPointsTransactionsProvider(user?.id ?? -1));

    return Scaffold(
      appBar: AppBar(title: const Text('我的积分')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.7)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '当前可用积分',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${user?.points ?? 0}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.stars, color: Colors.white, size: 24),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PointsApplicationScreen()),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('申请积分（提交审核）'),
          ),
          const SizedBox(height: 24),
          Text('积分明细', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          txAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => EmptyState(icon: Icons.error_outline, title: '加载失败', subtitle: '$e'),
            data: (list) {
              if (list.isEmpty) {
                return const EmptyState(icon: Icons.receipt_long_outlined, title: '暂无积分记录');
              }
              return Card(
                child: Column(
                  children: [
                    for (var i = 0; i < list.length; i++) ...[
                      _TxTile(tx: list[i]),
                      if (i != list.length - 1) const Divider(indent: 16, endIndent: 16),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TxTile extends StatelessWidget {
  const _TxTile({required this.tx});
  final PointsTransaction tx;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNegative = tx.amount < 0;
    final color = isNegative ? theme.colorScheme.error : theme.colorScheme.primary;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(
          tx.type == PointsTxType.redeem ? Icons.card_giftcard : Icons.swap_vert,
          color: color,
        ),
      ),
      title: Text(tx.displayLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        '${formatDateTime(tx.createdAt)}${tx.note == null || tx.note!.isEmpty ? '' : ' · ${tx.note}'}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            formatPoints(tx.amount),
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          ReviewStatusBadge(status: tx.status),
        ],
      ),
    );
  }
}
