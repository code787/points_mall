import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/database_helper.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/item_repository.dart';
import '../data/repositories/points_repository.dart';
import '../data/repositories/redemption_repository.dart';
import '../data/repositories/stats_repository.dart';
import '../data/repositories/user_repository.dart';

final dbHelperProvider = Provider<DatabaseHelper>((ref) => DatabaseHelper.instance);

final userRepoProvider = Provider<UserRepository>((ref) => LocalUserRepository(ref.watch(dbHelperProvider)));

final itemRepoProvider = Provider<ItemRepository>((ref) => LocalItemRepository(ref.watch(dbHelperProvider)));

final pointsRepoProvider = Provider<PointsRepository>((ref) => LocalPointsRepository(ref.watch(dbHelperProvider)));

final redemptionRepoProvider =
    Provider<RedemptionRepository>((ref) => LocalRedemptionRepository(ref.watch(dbHelperProvider)));

final authRepoProvider = Provider<AuthRepository>((ref) => AuthRepository(userRepository: ref.watch(userRepoProvider)));

final statsRepoProvider = Provider<StatsRepository>(
  (ref) => LocalStatsRepository(ref.watch(dbHelperProvider), ref.watch(pointsRepoProvider)),
);
