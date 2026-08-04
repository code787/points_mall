import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../data/models/enums.dart';
import '../../../../providers/feature_providers.dart';
import '../../../../widgets/empty_state.dart';
import '../../../../widgets/status_badge.dart';

class PointsTransactionsList extends ConsumerStatefulWidget {
  const PointsTransactionsList({super.key});

  @override
  ConsumerState<PointsTransactionsList> createState() => _PointsTransactionsListState();
}

class _PointsTransactionsListState extends ConsumerState<PointsTransactionsList> {
  static const _categories = ['积分申请', '积分奖励', '积分扣减', '兑换消费'];

  ReviewStatus? _filter;
  String? _category;
  int? _userId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final listAsync = ref.watch(allPointsTransactionsProvider);
    final usersAsync = ref.watch(usersProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: usersAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (users) {
              final candidates = users.where((u) => !u.isAdmin).toList();
              return DropdownButtonFormField<int?>(
                initialValue: _userId,
                isExpanded: true,
                decoration: const InputDecoration(
                  isDense: true,
                  labelText: '按用户筛选',
                  prefixIcon: Icon(Icons.person_search_outlined, size: 20),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('全部用户')),
                  for (final u in candidates)
                    DropdownMenuItem(value: u.id, child: Text(u.displayName)),
                ],
                onChanged: (v) => setState(() => _userId = v),
              );
            },
          ),
        ),
        _chipRow(
          children: [
            _FilterChip(
              label: '状态：全部',
              selected: _filter == null,
              onTap: () => setState(() => _filter = null),
            ),
            for (final s in ReviewStatus.values) ...[
              const SizedBox(width: 8),
              _FilterChip(
                label: s.label,
                selected: _filter == s,
                onTap: () => setState(() => _filter = s),
              ),
            ],
          ],
        ),
        _chipRow(
          children: [
            _FilterChip(
              label: '类别：全部',
              selected: _category == null,
              onTap: () => setState(() => _category = null),
            ),
            for (final c in _categories) ...[
              const SizedBox(width: 8),
              _FilterChip(
                label: c,
                selected: _category == c,
                onTap: () => setState(() => _category = c),
              ),
            ],
          ],
        ),
        Expanded(
          child: listAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => EmptyState(icon: Icons.error_outline, title: '加载失败', subtitle: '$e'),
            data: (list) {
              var filtered = list;
              if (_filter != null) filtered = filtered.where((t) => t.status == _filter).toList();
              if (_category != null) filtered = filtered.where((t) => t.displayLabel == _category).toList();
              if (_userId != null) filtered = filtered.where((t) => t.userId == _userId).toList();
              if (filtered.isEmpty) {
                return const EmptyState(icon: Icons.receipt_long_outlined, title: '暂无流水');
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final tx = filtered[index];
                  final isNegative = tx.amount < 0;
                  final color = isNegative ? theme.colorScheme.error : theme.colorScheme.primary;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: color.withValues(alpha: 0.12),
                        child: Icon(
                          tx.type == PointsTxType.redeem ? Icons.card_giftcard : Icons.swap_vert,
                          color: color,
                        ),
                      ),
                      title: Text(
                        '${tx.userName ?? '用户#${tx.userId}'} · ${tx.displayLabel}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
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
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _chipRow({required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: SizedBox(
        height: 38,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: children,
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      selectedColor: theme.colorScheme.primaryContainer,
      labelStyle: TextStyle(
        fontSize: 13,
        color: selected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}
