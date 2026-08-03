import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/dashboard/admin_dashboard_screen.dart';
import '../../features/admin/items/item_list_screen.dart';
import '../../features/admin/reviews/review_center_screen.dart';
import '../../features/admin/transactions/transaction_center_screen.dart';
import '../../features/admin/users/user_list_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/home/home_shell.dart';
import '../../features/user/orders/my_orders_screen.dart';
import '../../features/user/points/my_points_screen.dart';
import '../../features/user/profile/profile_screen.dart';
import '../../features/user/shop/shop_screen.dart';
import '../../providers/auth_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.read(authControllerProvider);
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: auth,
    redirect: (context, state) {
      if (!auth.isReady) return null;
      final loc = state.matchedLocation;
      if (!auth.isLoggedIn) return loc == '/login' ? null : '/login';
      if (auth.isAdmin) {
        if (loc == '/login' || loc.startsWith('/shop') || loc.startsWith('/my/')) return '/admin';
      } else {
        if (loc == '/login' || loc.startsWith('/admin')) return '/shop';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomeShell(navigationShell: navigationShell, isAdmin: true),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/admin', builder: (context, state) => const AdminDashboardScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/admin/users', builder: (context, state) => const UserListScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/admin/items', builder: (context, state) => const ItemListScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/admin/reviews', builder: (context, state) => const ReviewCenterScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/admin/transactions', builder: (context, state) => const TransactionCenterScreen()),
          ]),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomeShell(navigationShell: navigationShell, isAdmin: false),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/shop', builder: (context, state) => const ShopScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/my/points', builder: (context, state) => const MyPointsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/my/orders', builder: (context, state) => const MyOrdersScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/my/profile', builder: (context, state) => const ProfileScreen()),
          ]),
        ],
      ),
    ],
  );
});
