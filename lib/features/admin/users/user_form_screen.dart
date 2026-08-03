import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/validators.dart';
import '../../../data/models/app_user.dart';
import '../../../data/models/enums.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/repository_providers.dart';
import '../../../widgets/confirm_dialog.dart';

class UserFormScreen extends ConsumerStatefulWidget {
  const UserFormScreen({super.key, this.user});

  final AppUser? user;

  @override
  ConsumerState<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends ConsumerState<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _username;
  late final TextEditingController _displayName;
  late final TextEditingController _password;
  late final TextEditingController _initialPoints;
  late UserRole _role;
  late UserStatus _status;
  bool _saving = false;

  bool get _isEdit => widget.user != null;

  @override
  void initState() {
    super.initState();
    _username = TextEditingController(text: widget.user?.username ?? '');
    _displayName = TextEditingController(text: widget.user?.displayName ?? '');
    _password = TextEditingController();
    _initialPoints = TextEditingController();
    _role = widget.user?.role ?? UserRole.user;
    _status = widget.user?.status ?? UserStatus.active;
  }

  @override
  void dispose() {
    _username.dispose();
    _displayName.dispose();
    _password.dispose();
    _initialPoints.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(userRepoProvider);
      if (_isEdit) {
        final original = widget.user!;
        await repo.update(original.copyWith(
          displayName: _displayName.text.trim(),
          role: _role,
          status: _status,
        ));
        if (original.id == ref.read(authControllerProvider).user?.id) {
          await ref.read(authControllerProvider).refreshUser();
        }
        if (mounted) {
          showSnack(context, '保存成功');
          Navigator.of(context).pop(true);
        }
      } else {
        await repo.create(
          username: _username.text.trim(),
          password: _password.text,
          displayName: _displayName.text.trim(),
          role: _role,
          initialPoints: int.tryParse(_initialPoints.text.trim()) ?? 0,
        );
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
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? '编辑用户' : '新增用户')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _username,
              enabled: !_isEdit,
              validator: validateUsername,
              decoration: InputDecoration(
                labelText: '用户名',
                helperText: _isEdit ? '用户名不可修改' : null,
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _displayName,
              validator: validateDisplayName,
              decoration: const InputDecoration(
                labelText: '姓名 / 昵称',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),
            const SizedBox(height: 16),
            if (!_isEdit) ...[
              TextFormField(
                controller: _password,
                validator: validatePassword,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '初始密码',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _initialPoints,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final n = int.tryParse(v.trim());
                  if (n == null || n < 0) return '请输入大于等于 0 的整数';
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: '初始积分（可选）',
                  prefixIcon: Icon(Icons.stars_outlined),
                ),
              ),
              const SizedBox(height: 16),
            ],
            DropdownButtonFormField<UserRole>(
              initialValue: _role,
              decoration: const InputDecoration(labelText: '角色', prefixIcon: Icon(Icons.admin_panel_settings_outlined)),
              items: [
                for (final r in UserRole.values)
                  DropdownMenuItem(value: r, child: Text(r.label)),
              ],
              onChanged: (v) => setState(() => _role = v ?? _role),
            ),
            if (_isEdit) ...[
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('账号状态'),
                subtitle: Text(_status.label),
                value: _status == UserStatus.active,
                onChanged: (v) => setState(() => _status = v ? UserStatus.active : UserStatus.disabled),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                  : Text(_isEdit ? '保存' : '创建用户'),
            ),
          ],
        ),
      ),
    );
  }
}
