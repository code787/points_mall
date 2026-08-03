import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({
    super.key,
    required this.navigationShell,
    required this.isAdmin,
  });

  final StatefulNavigationShell navigationShell;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final destinations = isAdmin
        ? const [
            (icon: Icons.dashboard_outlined, selected: Icons.dashboard, label: '看板'),
            (icon: Icons.group_outlined, selected: Icons.group, label: '用户'),
            (icon: Icons.card_giftcard_outlined, selected: Icons.card_giftcard, label: '物品'),
            (icon: Icons.rule_outlined, selected: Icons.rule, label: '审核'),
            (icon: Icons.receipt_long_outlined, selected: Icons.receipt_long, label: '流水'),
          ]
        : const [
            (icon: Icons.storefront_outlined, selected: Icons.storefront, label: '商城'),
            (icon: Icons.stars_outlined, selected: Icons.stars, label: '我的积分'),
            (icon: Icons.local_activity_outlined, selected: Icons.local_activity, label: '兑换记录'),
            (icon: Icons.person_outline, selected: Icons.person, label: '我的'),
          ];

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        height: 64,
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: [
          for (final d in destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selected),
              label: d.label,
            ),
        ],
      ),
    );
  }
}
