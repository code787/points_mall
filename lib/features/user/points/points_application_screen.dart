import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/validators.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/feature_providers.dart';
import '../../../providers/repository_providers.dart';
import '../../../widgets/confirm_dialog.dart';

class PointsApplicationScreen extends ConsumerStatefulWidget {
  const PointsApplicationScreen({super.key});

  @override
  ConsumerState<PointsApplicationScreen> createState() => _PointsApplicationScreenState();
}

class _PointsApplicationScreenState extends ConsumerState<PointsApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    if (!_formKey.currentState!.validate()) return;
    final amount = int.tryParse(_amountController.text.trim()) ?? 0;
    setState(() => _saving = true);
    try {
      await ref.read(pointsRepoProvider).createRequest(
            userId: user.id,
            amount: amount,
            note: _reasonController.text.trim(),
          );
      ref.invalidate(userPointsTransactionsProvider(user.id));
      ref.invalidate(pendingPointsProvider);
      ref.invalidate(allPointsTransactionsProvider);
      if (mounted) {
        showSnack(context, '申请已提交，等待管理员审核');
        Navigator.of(context).pop(true);
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
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('申请积分')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              validator: (v) => validatePoints(v, allowNegative: false),
              decoration: const InputDecoration(
                labelText: '申请积分数量',
                prefixIcon: Icon(Icons.stars_outlined),
                helperText: '填写想要获得的积分（正整数）',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _reasonController,
              maxLength: 100,
              maxLines: 3,
              validator: (v) => validateRequired(v, field: '申请理由'),
              decoration: const InputDecoration(
                labelText: '申请理由',
                hintText: '例如：完成项目 A、本月全勤奖励等',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                  : const Text('提交申请'),
            ),
            const SizedBox(height: 12),
            Text(
              '当前可用积分：${user?.points ?? 0}\n提交后需管理员审核通过才会到账',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
            ),
          ],
        ),
      ),
    );
  }
}
