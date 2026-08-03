import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/enums.dart';
import '../../../data/models/mall_item.dart';
import '../../../providers/feature_providers.dart';
import '../../../providers/repository_providers.dart';
import '../../../widgets/confirm_dialog.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/item_avatar.dart';
import '../../../widgets/status_badge.dart';
import 'item_form_screen.dart';

class ItemListScreen extends ConsumerStatefulWidget {
  const ItemListScreen({super.key});

  @override
  ConsumerState<ItemListScreen> createState() => _ItemListScreenState();
}

class _ItemListScreenState extends ConsumerState<ItemListScreen> {
  Future<void> _refresh() async {
    ref.invalidate(itemsProvider);
    await ref.read(itemsProvider.future);
  }

  Future<void> _openActions(MallItem item) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _ItemActionsSheet(item: item),
    );
    if (action == null || !mounted) return;
    switch (action) {
      case 'edit':
        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ItemFormScreen(item: item)));
      case 'stock':
        await _adjustStock(item);
      case 'toggle':
        await _toggleStatus(item);
    }
    await _refresh();
  }

  Future<void> _adjustStock(MallItem item) async {
    final deltaText = await promptDialog(
      context,
      title: '调整库存',
      hint: '正数入库，负数出库（当前库存 ${item.stock}）',
      confirmText: '确定',
    );
    if (deltaText == null || deltaText.trim().isEmpty) return;
    if (!mounted) return;
    final delta = int.tryParse(deltaText.trim());
    if (delta == null || delta == 0) {
      showSnack(context, '请输入非 0 整数', isError: true);
      return;
    }
    await ref.read(itemRepoProvider).adjustStock(item.id, delta);
    if (mounted) showSnack(context, '库存已调整');
  }

  Future<void> _toggleStatus(MallItem item) async {
    final target = item.status == ItemStatus.active ? ItemStatus.inactive : ItemStatus.active;
    final ok = await confirmDialog(
      context,
      title: target == ItemStatus.inactive ? '下架物品' : '上架物品',
      message: target == ItemStatus.inactive
          ? '确定下架「${item.name}」？下架后用户将无法兑换。'
          : '确定上架「${item.name}」？',
      confirmText: target == ItemStatus.inactive ? '下架' : '上架',
    );
    if (!ok) return;
    await ref.read(itemRepoProvider).setStatus(item.id, target);
    if (mounted) showSnack(context, '操作成功');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final itemsAsync = ref.watch(itemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('物品管理'),
        actions: [
          IconButton(
            tooltip: '新增物品',
            icon: const Icon(Icons.add_box_outlined),
            onPressed: () async {
              await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ItemFormScreen()));
              _refresh();
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(icon: Icons.error_outline, title: '加载失败', subtitle: '$e'),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.card_giftcard_outlined,
              title: '暂无物品',
              subtitle: '点击右上角添加兑换物品',
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      leading: ItemAvatar(emoji: item.emoji, color: item.color, size: 48),
                      title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        '库存 ${item.stock}',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
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
                              Text('${item.pointsCost}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ItemStatusBadge(status: item.status),
                        ],
                      ),
                      onTap: () => _openActions(item),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ItemActionsSheet extends StatelessWidget {
  const _ItemActionsSheet({required this.item});
  final MallItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final targetLabel = item.status == ItemStatus.active ? '下架' : '上架';
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ItemAvatar(emoji: item.emoji, color: item.color, size: 52),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${item.pointsCost} 积分 · 库存 ${item.stock}',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              leading: const Icon(Icons.edit_outlined),
              title: const Text('编辑物品'),
              trailing: const Icon(Icons.chevron_right, color: Color(0xFFBDBDBD)),
              onTap: () => Navigator.of(context).pop('edit'),
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              leading: const Icon(Icons.inventory_2_outlined),
              title: const Text('调整库存'),
              trailing: const Icon(Icons.chevron_right, color: Color(0xFFBDBDBD)),
              onTap: () => Navigator.of(context).pop('stock'),
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              leading: Icon(
                item.status == ItemStatus.active ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: theme.colorScheme.primary,
              ),
              title: Text('$targetLabel物品', style: TextStyle(color: theme.colorScheme.primary)),
              trailing: const Icon(Icons.chevron_right, color: Color(0xFFBDBDBD)),
              onTap: () => Navigator.of(context).pop('toggle'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('关闭'),
            ),
          ],
        ),
      ),
    );
  }
}
