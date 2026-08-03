import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/mall_item.dart';
import '../../../providers/feature_providers.dart';
import '../../../providers/repository_providers.dart';
import '../../../widgets/confirm_dialog.dart';

class ItemFormScreen extends ConsumerStatefulWidget {
  const ItemFormScreen({super.key, this.item});

  final MallItem? item;

  @override
  ConsumerState<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends ConsumerState<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _pointsCost;
  late final TextEditingController _stock;
  late String _emoji;
  late int _color;
  late ItemStatus _status;
  bool _saving = false;

  bool get _isEdit => widget.item != null;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.item?.name ?? '');
    _description = TextEditingController(text: widget.item?.description ?? '');
    _pointsCost = TextEditingController(text: widget.item?.pointsCost.toString() ?? '');
    _stock = TextEditingController(text: widget.item?.stock.toString() ?? '');
    _emoji = widget.item?.emoji ?? AppConstants.itemEmojis.first;
    _color = widget.item?.color ?? AppConstants.itemColors.first.value;
    _status = widget.item?.status ?? ItemStatus.active;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _pointsCost.dispose();
    _stock.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(itemRepoProvider);
      if (_isEdit) {
        final original = widget.item!;
        await repo.update(MallItem(
          id: original.id,
          name: _name.text.trim(),
          description: _description.text.trim(),
          pointsCost: int.parse(_pointsCost.text.trim()),
          stock: int.parse(_stock.text.trim()),
          emoji: _emoji,
          color: _color,
          status: _status,
          createdAt: original.createdAt,
          updatedAt: DateTime.now(),
        ));
        if (mounted) {
          showSnack(context, '保存成功');
          Navigator.of(context).pop(true);
        }
      } else {
        await repo.create(
          name: _name.text.trim(),
          description: _description.text.trim(),
          pointsCost: int.parse(_pointsCost.text.trim()),
          stock: int.parse(_stock.text.trim()),
          emoji: _emoji,
          color: _color,
        );
        ref.invalidate(itemsProvider);
        ref.invalidate(shopItemsProvider);
        if (mounted) {
          showSnack(context, '创建成功');
          Navigator.of(context).pop(true);
        }
      }
    } on Exception catch (e) {
      if (mounted) showSnack(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? '编辑物品' : '新增物品')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Color(_color).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(_emoji, style: const TextStyle(fontSize: 44)),
                  ),
                  const SizedBox(height: 8),
                  Text('物品样式预览', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('选择图标', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final emoji in AppConstants.itemEmojis)
                  GestureDetector(
                    onTap: () => setState(() => _emoji = emoji),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _emoji == emoji ? Color(_color).withValues(alpha: 0.2) : const Color(0xFFF0F1F5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _emoji == emoji ? Color(_color) : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 22)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text('选择颜色', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final c in AppConstants.itemColors)
                  GestureDetector(
                    onTap: () => setState(() => _color = c.value),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Color(c.value),
                        shape: BoxShape.circle,
                        border: _color == c.value
                            ? Border.all(color: theme.colorScheme.onSurface, width: 2.5)
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _name,
              validator: (v) => validateRequired(v, field: '物品名称'),
              decoration: const InputDecoration(labelText: '物品名称', prefixIcon: Icon(Icons.label_outline)),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _pointsCost,
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return '请输入积分';
                final n = int.tryParse(v.trim());
                if (n == null || n <= 0) return '积分需为大于 0 的整数';
                return null;
              },
              decoration: const InputDecoration(
                labelText: '兑换积分',
                prefixIcon: Icon(Icons.stars_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _stock,
              keyboardType: TextInputType.number,
              validator: validateStock,
              decoration: const InputDecoration(
                labelText: '库存数量',
                prefixIcon: Icon(Icons.inventory_2_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _description,
              maxLines: 3,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: '物品描述（选填）',
                alignLabelWithHint: true,
                hintText: '介绍物品详情',
              ),
            ),
            if (_isEdit) ...[
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('上架状态'),
                subtitle: Text(_status.label),
                value: _status == ItemStatus.active,
                onChanged: (v) =>
                    setState(() => _status = v ? ItemStatus.active : ItemStatus.inactive),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                  : Text(_isEdit ? '保存' : '创建物品'),
            ),
          ],
        ),
      ),
    );
  }
}
