import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/models/mall_item.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/feature_providers.dart';
import '../../../providers/repository_providers.dart';
import '../../../widgets/confirm_dialog.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/item_avatar.dart';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  bool _submitting = false;

  void _showItemDetail(MallItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _RedeemSheet(
        item: item,
        submitting: _submitting,
        onSubmit: _submitRedemption,
      ),
    );
  }

  Future<void> _submitRedemption(MallItem item, int quantity) async {
    if (_submitting) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    setState(() => _submitting = true);
    try {
      await ref.read(redemptionRepoProvider).createRequest(
            userId: user.id,
            itemId: item.id,
            quantity: quantity,
          );
      ref.invalidate(userRedemptionRequestsProvider(user.id));
      if (mounted) {
        Navigator.of(context).pop();
        showSnack(context, '兑换申请已提交，等待管理员审核');
      }
    } on Exception catch (e) {
      if (mounted) showSnack(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final itemsAsync = ref.watch(shopItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('积分商城'),
        actions: [
          IconButton(
            tooltip: '刷新商品',
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              ref.invalidate(shopItemsProvider);
              await ref.read(shopItemsProvider.future);
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.stars, size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      '${user?.points ?? 0}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(icon: Icons.error_outline, title: '加载失败', subtitle: '$e'),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.storefront_outlined,
              title: '暂无商品',
              subtitle: '管理员尚未上架可兑换物品',
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(shopItemsProvider);
              await ref.read(shopItemsProvider.future);
            },
            child: GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.82,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return _ItemCard(item: item, onTap: () => _showItemDetail(item));
              },
            ),
          );
        },
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item, required this.onTap});
  final MallItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final outOfStock = item.stock <= 0;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: outOfStock ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ItemAvatar(emoji: item.emoji, color: item.color, size: 52),
                  if (outOfStock)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '缺货',
                        style: TextStyle(fontSize: 11, color: Color(0xFFE53935), fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.stars, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    '${item.pointsCost}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '库存 ${item.stock}',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RedeemSheet extends ConsumerStatefulWidget {
  const _RedeemSheet({
    required this.item,
    required this.submitting,
    required this.onSubmit,
  });

  final MallItem item;
  final bool submitting;
  final void Function(MallItem item, int quantity) onSubmit;

  @override
  ConsumerState<_RedeemSheet> createState() => _RedeemSheetState();
}

class _RedeemSheetState extends ConsumerState<_RedeemSheet> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = widget.item;
    final user = ref.watch(currentUserProvider);
    final userPoints = user?.points ?? 0;
    final total = item.pointsCost * _quantity;
    final insufficient = userPoints < total;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: const Color(0xFFEDEFF4), borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ItemAvatar(emoji: item.emoji, color: item.color, size: 64),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      item.description.isEmpty ? '暂无描述' : item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(Icons.stars, color: theme.colorScheme.primary),
              const SizedBox(width: 4),
              Text('${item.pointsCost} / 件',
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('库存 ${item.stock}', style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('兑换数量', style: theme.textTheme.titleSmall),
              Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                    icon: const Icon(Icons.remove, size: 20),
                  ),
                  SizedBox(
                    width: 44,
                    child: Text(
                      '$_quantity',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: _quantity < item.stock ? () => setState(() => _quantity++) : null,
                    icon: const Icon(Icons.add, size: 20),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('合计', style: theme.textTheme.titleSmall),
              Row(
                children: [
                  Icon(Icons.stars, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    '$total',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (insufficient) ...[
            const SizedBox(height: 8),
            Text(
              '当前积分 ${formatPointsPlain(userPoints)}，积分不足',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: widget.submitting || insufficient ? null : () => widget.onSubmit(item, _quantity),
            child: widget.submitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : const Text('提交兑换申请'),
          ),
        ],
      ),
    );
  }
}
