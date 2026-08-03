import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/app_user.dart';
import '../data/models/enums.dart';
import '../data/models/mall_item.dart';
import '../data/models/points_transaction.dart';
import '../data/models/redemption_request.dart';
import '../data/models/stats_summary.dart';
import 'repository_providers.dart';

final usersProvider = FutureProvider<List<AppUser>>((ref) => ref.watch(userRepoProvider).getAll());

final itemsProvider = FutureProvider<List<MallItem>>(
  (ref) => ref.watch(itemRepoProvider).getAll(includeInactive: true),
);

final shopItemsProvider = FutureProvider<List<MallItem>>(
  (ref) => ref.watch(itemRepoProvider).getAll(includeInactive: false),
);

final pendingPointsProvider = FutureProvider<List<PointsTransaction>>(
  (ref) => ref.watch(pointsRepoProvider).getAll(status: ReviewStatus.pending),
);

final pendingRedemptionsProvider = FutureProvider<List<RedemptionRequest>>(
  (ref) => ref.watch(redemptionRepoProvider).getAll(status: ReviewStatus.pending),
);

final allPointsTransactionsProvider = FutureProvider<List<PointsTransaction>>(
  (ref) => ref.watch(pointsRepoProvider).getAll(),
);

final allRedemptionRequestsProvider = FutureProvider<List<RedemptionRequest>>(
  (ref) => ref.watch(redemptionRepoProvider).getAll(),
);

final userPointsTransactionsProvider = FutureProvider.family<List<PointsTransaction>, int>(
  (ref, userId) => ref.watch(pointsRepoProvider).getAll(userId: userId),
);

final userRedemptionRequestsProvider = FutureProvider.family<List<RedemptionRequest>, int>(
  (ref, userId) => ref.watch(redemptionRepoProvider).getAll(userId: userId),
);

final statsProvider = FutureProvider<StatsSummary>((ref) => ref.watch(statsRepoProvider).getSummary());
