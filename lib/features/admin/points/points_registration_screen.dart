import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/validators.dart';
import '../../../data/models/app_user.dart';
import '../../../providers/feature_providers.dart';
import '../../../providers/repository_providers.dart';
import '../../../widgets/confirm_dialog.dart';

class PointsRegistrationScreen extends ConsumerStatefulWidget {
  const PointsRegistrationScreen({super.key, this.preselectedUser});

  final AppUser? preselectedUser;

  @override
  ConsumerState<PointsRegistrationScreen> createState() => _PointsRegistrationScreenState();
}

class _PointsRegistrationScreenState extends ConsumerState<PointsRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  int? _userId;
  bool _isAdd = true;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _userId = widget.preselectedUser?.id;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_userId == null) {
      showSnack(context, '请选择用户', isError: true);
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    final amount = (int.tryParse(_amountController.text.trim()) ?? 0) * (_isAdd ? 1 : -1);
    setState(() => _saving = true);
    try {
      await ref.read(pointsRepoProvider).createRequest(
            userId: _userId!,
            amount: amount,
            note: _noteController.text.trim(),
          );
      ref.invalidate(pendingPointsProvider);
      ref.invalidate(allPointsTransactionsProvider);
      ref.invalidate(userPointsTransactionsProvider(_userId!));
      if (mounted) {
        showSnack(context, '积分登记已提交，等待审核');
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
    final usersAsync = ref.watch(usersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('积分登记')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            usersAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('加载失败：$e'),
              data: (users) {
                final candidates = widget.preselectedUser != null
                    ? users.where((u) => u.id == widget.preselectedUser!.id).toList()
                    : users.where((u) => !u.isAdmin).toList();
                return DropdownButtonFormField<int>(
                  value: _userId,
                  decoration: const InputDecoration(
                    labelText: '目标用户',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  items: [
                    for (final u in candidates)
                      DropdownMenuItem(value: u.id, child: Text('${u.displayName}（积分 ${u.points}）')),
                  ],
                  onChanged: candidates.isEmpty ? null : (v) => setState(() => _userId = v),
                  validator: (_) => _userId == null ? '请选择用户' : null,
                );
              },
            ),
            const SizedBox(height: 20),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, icon: Icon(Icons.add), label: Text('加分')),
                ButtonSegment(value: false, icon: Icon(Icons.remove), label: Text('扣分')),
              ],
              selected: {_isAdd},
              onSelectionChanged: (s) => setState(() => _isAdd = s.first),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              validator: validatePoints,
              decoration: InputDecoration(
                labelText: '积分数量',
                prefixIcon: const Icon(Icons.stars_outlined),
                helperText: _isAdd ? '将增加该用户积分' : '将从该用户扣除积分',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteController,
              maxLength: 100,
              decoration: const InputDecoration(
                labelText: '备注（选填）',
                hintText: '例如：月度奖励、迟到扣分等',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                  : const Text('提交登记'),
            ),
            const SizedBox(height: 12),
            Text(
              '提交后需管理员审核通过才会实际增减积分',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
            ),
          ],
        ),
      ),
    );
  }
}
