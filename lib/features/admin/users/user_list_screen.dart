import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/app_user.dart';
import '../../../data/models/enums.dart';
import '../../../providers/feature_providers.dart';
import '../../../providers/repository_providers.dart';
import '../../../widgets/confirm_dialog.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/item_avatar.dart';
import '../../../widgets/status_badge.dart';
import '../points/points_registration_screen.dart';
import 'user_form_screen.dart';

class UserListScreen extends ConsumerStatefulWidget {
  const UserListScreen({super.key});

  @override
  ConsumerState<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends ConsumerState<UserListScreen> {
  String _keyword = '';

  Future<void> _refresh() async {
    ref.invalidate(usersProvider);
    await ref.read(usersProvider.future);
  }

  Future<void> _openActions(AppUser user) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _UserActionsSheet(user: user),
    );
    if (action == null || !mounted) return;
    switch (action) {
      case 'edit':
        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => UserFormScreen(user: user)));
      case 'points':
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PointsRegistrationScreen(preselectedUser: user)),
        );
      case 'reset':
        await _resetPassword(user);
      case 'toggle':
        await _toggleStatus(user);
    }
    await _refresh();
  }

  Future<void> _resetPassword(AppUser user) async {
    final newPassword = await promptDialog(context, title: '重置密码', hint: '输入新密码（至少 6 位）');
    if (newPassword == null || newPassword.trim().isEmpty) return;
    if (!mounted) return;
    if (newPassword.length < 6) {
      showSnack(context, '密码至少 6 位', isError: true);
      return;
    }
    await ref.read(userRepoProvider).resetPassword(user.id, newPassword);
    if (mounted) showSnack(context, '已重置「${user.displayName}」的密码');
  }

  Future<void> _toggleStatus(AppUser user) async {
    final target = user.status == UserStatus.active ? UserStatus.disabled : UserStatus.active;
    final ok = await confirmDialog(
      context,
      title: target == UserStatus.disabled ? '停用用户' : '启用用户',
      message: target == UserStatus.disabled
          ? '确定停用「${user.displayName}」？停用后该用户无法登录。'
          : '确定启用「${user.displayName}」？',
      confirmText: target == UserStatus.disabled ? '停用' : '启用',
      confirmColor: target == UserStatus.disabled ? const Color(0xFFE53935) : null,
    );
    if (!ok) return;
    await ref.read(userRepoProvider).setStatus(user.id, target);
    if (mounted) showSnack(context, '操作成功');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usersAsync = ref.watch(usersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('用户管理'),
        actions: [
          IconButton(
            tooltip: '新增用户',
            icon: const Icon(Icons.person_add_alt_1_outlined),
            onPressed: () async {
              await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UserFormScreen()));
              _refresh();
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              onChanged: (v) => setState(() => _keyword = v),
              decoration: const InputDecoration(
                hintText: '搜索用户名 / 昵称',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: usersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => EmptyState(icon: Icons.error_outline, title: '加载失败', subtitle: '$e'),
              data: (users) {
                final filtered = _keyword.isEmpty
                    ? users
                    : users
                        .where((u) => u.username.contains(_keyword) || u.displayName.contains(_keyword))
                        .toList();
                if (filtered.isEmpty) {
                  return const EmptyState(icon: Icons.group_outlined, title: '暂无用户');
                }
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final user = filtered[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Card(
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            leading: UserAvatar(name: user.displayName),
                            title: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    user.displayName,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                RoleBadge(role: user.role),
                              ],
                            ),
                            subtitle: Text(
                              '@${user.username}',
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
                                    Text(
                                      '${user.points}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                UserStatusBadge(status: user.status),
                              ],
                            ),
                            onTap: () => _openActions(user),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UserActionsSheet extends StatelessWidget {
  const _UserActionsSheet({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final target = user.status == UserStatus.active ? '停用' : '启用';
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                UserAvatar(name: user.displayName, size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '@${user.username} · 积分 ${user.points}',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const _ActionTile(icon: Icons.edit_outlined, label: '编辑资料', value: 'edit'),
            const _ActionTile(icon: Icons.add_circle_outline, label: '积分登记（加/扣分）', value: 'points'),
            const _ActionTile(icon: Icons.lock_reset, label: '重置密码', value: 'reset'),
            _ActionTile(
              icon: target == '停用' ? Icons.block : Icons.check_circle_outline,
              label: '$target用户',
              value: 'toggle',
              color: target == '停用' ? theme.colorScheme.error : theme.colorScheme.primary,
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

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.label, required this.value, this.color});
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = color ?? theme.colorScheme.onSurface;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Icon(icon, color: c),
      title: Text(label, style: TextStyle(color: c)),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFFBDBDBD)),
      onTap: () => Navigator.of(context).pop(value),
    );
  }
}
