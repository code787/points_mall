import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/points_transaction.dart';
import '../../../data/models/stats_summary.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/feature_providers.dart';
import '../../../widgets/confirm_dialog.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/stat_card.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final statsAsync = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('数据看板'),
        actions: [
          IconButton(
            tooltip: '退出登录',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final ok = await confirmDialog(context, title: '退出登录', message: '确定要退出当前账号吗？');
              if (ok) ref.read(authControllerProvider).logout();
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(statsProvider),
        child: statsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => EmptyState(icon: Icons.error_outline, title: '加载失败', subtitle: '$e'),
          data: (stats) => _DashboardBody(user: user?.displayName ?? '', stats: stats),
        ),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.user, required this.stats});
  final String user;
  final StatsSummary stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '你好，$user',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          '欢迎回来，今天也要元气满满',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: StatCard(
                icon: Icons.group_outlined,
                iconColor: theme.colorScheme.primary,
                label: '用户数',
                value: '${stats.totalUsers}',
                onTap: () => context.go('/admin/users'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                icon: Icons.card_giftcard_outlined,
                iconColor: const Color(0xFF00897B),
                label: '上架物品',
                value: '${stats.activeItems}',
                onTap: () => context.go('/admin/items'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatCard(
                icon: Icons.rule_outlined,
                iconColor: const Color(0xFFFB8C00),
                label: '待审积分',
                value: '${stats.pendingPointsRequests}',
                onTap: () => context.go('/admin/reviews'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                icon: Icons.pending_actions_outlined,
                iconColor: const Color(0xFFE53935),
                label: '待审兑换',
                value: '${stats.pendingRedemptions}',
                onTap: () => context.go('/admin/reviews'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatCard(
                icon: Icons.check_circle_outline,
                iconColor: const Color(0xFF43A047),
                label: '已完成兑换',
                value: '${stats.approvedRedemptions}',
                onTap: () => context.go('/admin/transactions'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                icon: Icons.stars_outlined,
                iconColor: const Color(0xFF8E24AA),
                label: '累计发放积分',
                value: '${stats.totalPointsIssued}',
                onTap: () => context.go('/admin/transactions'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('月度兑换趋势', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: stats.monthly.isEmpty
                ? const EmptyState(icon: Icons.show_chart, title: '暂无兑换数据', subtitle: '完成兑换后这里会显示月度趋势')
                : _MonthlyChart(data: stats.monthly),
          ),
        ),
        const SizedBox(height: 24),
        Text('最近兑换流水', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        stats.recentTransactions.isEmpty
            ? const EmptyState(icon: Icons.receipt_long_outlined, title: '暂无流水')
            : Card(
                child: Column(
                  children: [
                    for (var i = 0; i < stats.recentTransactions.length; i++) ...[
                      _RecentTx(tx: stats.recentTransactions[i]),
                      if (i != stats.recentTransactions.length - 1) const Divider(indent: 16, endIndent: 16),
                    ],
                  ],
                ),
              ),
      ],
    );
  }
}

class _RecentTx extends StatelessWidget {
  const _RecentTx({required this.tx});
  final PointsTransaction tx;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNegative = tx.amount < 0;
    final color = isNegative ? theme.colorScheme.error : theme.colorScheme.primary;
    return ListTile(
      dense: true,
      leading: Icon(
        tx.type == PointsTxType.redeem ? Icons.card_giftcard : Icons.swap_vert,
        color: color,
      ),
      title: Text(
        '${tx.userName ?? '用户#${tx.userId}'} · ${tx.displayLabel}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        formatDateTime(tx.createdAt),
        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
      ),
      trailing: Text(
        formatPoints(tx.amount),
        style: TextStyle(fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}

class _MonthlyChart extends StatelessWidget {
  const _MonthlyChart({required this.data});
  final List<MonthlyRedeem> data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxCost = data.map((e) => e.totalCost).fold<int>(1, (a, b) => a > b ? a : b);
    return Column(
      children: [
        for (final item in data) ...[
          Row(
            children: [
              SizedBox(
                width: 52,
                child: Text(item.month, style: theme.textTheme.bodySmall),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth * (item.totalCost / maxCost);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 20,
                          width: width <= 4 && item.totalCost > 0 ? 4 : width,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary.withValues(alpha: 0.7),
                                theme.colorScheme.primary,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 64,
                child: Text(
                  '${item.count} 单 · ${item.totalCost}',
                  textAlign: TextAlign.right,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
