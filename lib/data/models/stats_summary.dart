import 'points_transaction.dart';

class StatsSummary {
  const StatsSummary({
    required this.totalUsers,
    required this.activeUsers,
    required this.totalItems,
    required this.activeItems,
    required this.pendingPointsRequests,
    required this.pendingRedemptions,
    required this.approvedRedemptions,
    required this.totalPointsIssued,
    required this.totalPointsRedeemed,
    required this.recentTransactions,
    required this.monthly,
  });

  final int totalUsers;
  final int activeUsers;
  final int totalItems;
  final int activeItems;
  final int pendingPointsRequests;
  final int pendingRedemptions;
  final int approvedRedemptions;
  final int totalPointsIssued;
  final int totalPointsRedeemed;
  final List<PointsTransaction> recentTransactions;
  final List<MonthlyRedeem> monthly;
}

class MonthlyRedeem {
  const MonthlyRedeem({
    required this.month,
    required this.count,
    required this.totalCost,
  });

  final String month;
  final int count;
  final int totalCost;
}
