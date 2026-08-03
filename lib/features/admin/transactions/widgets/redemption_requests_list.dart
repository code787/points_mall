import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../data/models/enums.dart';
import '../../../../providers/feature_providers.dart';
import '../../../../widgets/empty_state.dart';
import '../../../../widgets/item_avatar.dart';
import '../../../../widgets/status_badge.dart';

class RedemptionRequestsList extends ConsumerStatefulWidget {
  const RedemptionRequestsList({super.key});

  @override
  ConsumerState<RedemptionRequestsList> createState() => _RedemptionRequestsListState();
}

class _RedemptionRequestsListState extends ConsumerState<RedemptionRequestsList> {
  ReviewStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final listAsync = ref.watch(allRedemptionRequestsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _FilterChip(
                  label: '全部',
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
          ),
        ),
        Expanded(
          child: listAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => EmptyState(icon: Icons.error_outline, title: '加载失败', subtitle: '$e'),
            data: (list) {
              final filtered = _filter == null ? list : list.where((r) => r.status == _filter).toList();
              if (filtered.isEmpty) {
                return const EmptyState(icon: Icons.local_activity_outlined, title: '暂无兑换申请');
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final req = filtered[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: ItemAvatar(emoji: req.itemEmoji ?? '🎁', color: req.itemColor ?? 0xFF1E88E5, size: 44),
                      title: Text(
                        req.itemName ?? '物品',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${req.userName ?? '用户#${req.userId}'} · x${req.quantity} · ${formatDateTime(req.createdAt)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
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
                          ReviewStatusBadge(status: req.status),
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
