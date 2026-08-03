import 'package:sqflite/sqflite.dart';

import '../local/database_helper.dart';
import '../models/enums.dart';
import '../models/points_transaction.dart';
import '../models/stats_summary.dart';
import 'points_repository.dart';

abstract class StatsRepository {
  Future<StatsSummary> getSummary();
}

class LocalStatsRepository implements StatsRepository {
  LocalStatsRepository(this._db, this.pointsRepository);
  final DatabaseHelper _db;
  final PointsRepository pointsRepository;

  @override
  Future<StatsSummary> getSummary() async {
    final db = await _db.database;

    Future<int> count(String sql, [List<Object?>? args]) async {
      final rows = await db.rawQuery(sql, args);
      return Sqflite.firstIntValue(rows) ?? 0;
    }

    final totalUsers = await count("SELECT COUNT(*) FROM users WHERE role = 'user'");
    final activeUsers = await count("SELECT COUNT(*) FROM users WHERE role = 'user' AND status = 'active'");
    final totalItems = await count('SELECT COUNT(*) FROM items');
    final activeItems = await count("SELECT COUNT(*) FROM items WHERE status = 'active'");
    final pendingPointsRequests = await count("SELECT COUNT(*) FROM points_transactions WHERE status = 'pending'");
    final pendingRedemptions = await count("SELECT COUNT(*) FROM redemption_requests WHERE status = 'pending'");
    final approvedRedemptions = await count("SELECT COUNT(*) FROM redemption_requests WHERE status = 'approved'");

    final issuedRows = await db.rawQuery(
      "SELECT COALESCE(SUM(amount), 0) AS s FROM points_transactions WHERE status = 'approved' AND amount > 0",
    );
    final totalPointsIssued = (issuedRows.first['s'] as num).toInt();

    final redeemedRows = await db.rawQuery(
      "SELECT COALESCE(SUM(-amount), 0) AS s FROM points_transactions WHERE status = 'approved' AND type = 'redeem'",
    );
    final totalPointsRedeemed = (redeemedRows.first['s'] as num).toInt();

    final recentRows = await db.rawQuery('''
      SELECT pts.*, u.display_name AS user_name
      FROM points_transactions pts
      LEFT JOIN users u ON u.id = pts.user_id
      WHERE pts.status = 'approved'
      ORDER BY pts.created_at DESC
      LIMIT 8
    ''');
    final recent = recentRows.map(PointsTransaction.fromMap).toList();

    final monthlyRows = await db.rawQuery('''
      SELECT strftime('%Y-%m', created_at / 1000, 'unixepoch', 'localtime') AS month,
             COUNT(*) AS cnt, COALESCE(SUM(total_cost), 0) AS cost
      FROM redemption_requests
      WHERE status = 'approved'
      GROUP BY month
      ORDER BY month DESC
      LIMIT 12
    ''');
    final monthly = monthlyRows
        .map((r) => MonthlyRedeem(
              month: r['month'] as String,
              count: (r['cnt'] as num).toInt(),
              totalCost: (r['cost'] as num).toInt(),
            ))
        .toList()
        .reversed
        .toList();

    return StatsSummary(
      totalUsers: totalUsers,
      activeUsers: activeUsers,
      totalItems: totalItems,
      activeItems: activeItems,
      pendingPointsRequests: pendingPointsRequests,
      pendingRedemptions: pendingRedemptions,
      approvedRedemptions: approvedRedemptions,
      totalPointsIssued: totalPointsIssued,
      totalPointsRedeemed: totalPointsRedeemed,
      recentTransactions: recent,
      monthly: monthly,
    );
  }
}
