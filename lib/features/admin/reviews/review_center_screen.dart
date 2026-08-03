import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/feature_providers.dart';
import 'widgets/points_review_list.dart';
import 'widgets/redemption_review_list.dart';

class ReviewCenterScreen extends ConsumerWidget {
  const ReviewCenterScreen({super.key});

  Future<void> _refreshAll(WidgetRef ref) async {
    ref.invalidate(pendingPointsProvider);
    ref.invalidate(pendingRedemptionsProvider);
    await Future.wait([
      ref.read(pendingPointsProvider.future),
      ref.read(pendingRedemptionsProvider.future),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingPoints = ref.watch(pendingPointsProvider).valueOrNull?.length ?? 0;
    final pendingRedemptions = ref.watch(pendingRedemptionsProvider).valueOrNull?.length ?? 0;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('审核中心'),
          bottom: TabBar(
            tabs: [
              Tab(text: '积分审核${pendingPoints > 0 ? ' ($pendingPoints)' : ''}'),
              Tab(text: '兑换审核${pendingRedemptions > 0 ? ' ($pendingRedemptions)' : ''}'),
            ],
          ),
          actions: [
            IconButton(
              tooltip: '刷新',
              icon: const Icon(Icons.refresh),
              onPressed: () => _refreshAll(ref),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: const TabBarView(
          children: [
            PointsReviewList(),
            RedemptionReviewList(),
          ],
        ),
      ),
    );
  }
}
