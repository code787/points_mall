import '../local/database_helper.dart';
import '../models/app_user.dart';
import '../models/enums.dart';
import '../models/mall_item.dart';
import '../models/redemption_request.dart';

abstract class RedemptionRepository {
  Future<List<RedemptionRequest>> getAll({int? userId, ReviewStatus? status});
  Future<RedemptionRequest?> getById(int id);
  Future<RedemptionRequest> createRequest({
    required int userId,
    required int itemId,
    required int quantity,
    String? note,
  });
  Future<void> approve(int requestId, int operatorId);
  Future<void> reject(int requestId, int operatorId, {String? reason});
}

class RedemptionException implements Exception {
  final String message;
  const RedemptionException(this.message);
  @override
  String toString() => message;
}

class LocalRedemptionRepository implements RedemptionRepository {
  LocalRedemptionRepository(this._db);
  final DatabaseHelper _db;

  static const String _select = '''
    SELECT r.*, u.display_name AS user_name, i.name AS item_name,
           i.emoji AS item_emoji, i.color AS item_color
    FROM redemption_requests r
    LEFT JOIN users u ON u.id = r.user_id
    LEFT JOIN items i ON i.id = r.item_id
  ''';

  @override
  Future<RedemptionRequest?> getById(int id) async {
    final db = await _db.database;
    final rows = await db.rawQuery('$_select WHERE r.id = ?', [id]);
    if (rows.isEmpty) return null;
    return RedemptionRequest.fromMap(rows.first);
  }

  @override
  Future<List<RedemptionRequest>> getAll({int? userId, ReviewStatus? status}) async {
    final db = await _db.database;
    final where = <String>[];
    final args = <Object?>[];
    if (userId != null) {
      where.add('r.user_id = ?');
      args.add(userId);
    }
    if (status != null) {
      where.add('r.status = ?');
      args.add(status.name);
    }
    var sql = _select;
    if (where.isNotEmpty) sql += ' WHERE ${where.join(' AND ')}';
    sql += ' ORDER BY r.created_at DESC, r.id DESC';
    final rows = await db.rawQuery(sql, args);
    return rows.map(RedemptionRequest.fromMap).toList();
  }

  @override
  Future<RedemptionRequest> createRequest({
    required int userId,
    required int itemId,
    required int quantity,
    String? note,
  }) async {
    if (quantity <= 0) throw const RedemptionException('兑换数量必须大于 0');
    final db = await _db.database;

    final itemRows = await db.query('items', where: 'id = ?', whereArgs: [itemId]);
    if (itemRows.isEmpty) throw const RedemptionException('物品不存在');
    final item = MallItem.fromMap(itemRows.first);
    if (item.status != ItemStatus.active) throw const RedemptionException('该物品已下架');
    if (item.stock < quantity) throw RedemptionException('库存不足，当前仅剩 ${item.stock} 件');

    final userRows = await db.query('users', where: 'id = ?', whereArgs: [userId]);
    if (userRows.isEmpty) throw const RedemptionException('用户不存在');
    final user = AppUser.fromMap(userRows.first);
    if (user.status != UserStatus.active) throw const RedemptionException('用户已被停用');
    final totalCost = item.pointsCost * quantity;
    if (user.points < totalCost) {
      throw RedemptionException('积分不足，需要 $totalCost 积分，当前余额 ${user.points}');
    }

    final id = await db.insert('redemption_requests', {
      'user_id': userId,
      'item_id': itemId,
      'quantity': quantity,
      'total_cost': totalCost,
      'status': ReviewStatus.pending.name,
      'note': note?.trim().isEmpty ?? true ? null : note!.trim(),
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
    await _db.notifyDataChanged();
    return (await getById(id))!;
  }

  @override
  Future<void> approve(int requestId, int operatorId) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      final rows = await txn.query('redemption_requests', where: 'id = ?', whereArgs: [requestId]);
      if (rows.isEmpty) throw const RedemptionException('申请不存在');
      final req = RedemptionRequest.fromMap(rows.first);
      if (req.status != ReviewStatus.pending) throw const RedemptionException('该申请已被处理');

      final itemRows = await txn.query('items', where: 'id = ?', whereArgs: [req.itemId]);
      if (itemRows.isEmpty) throw const RedemptionException('物品不存在');
      final item = MallItem.fromMap(itemRows.first);
      if (item.stock < req.quantity) {
        throw RedemptionException('库存不足，当前仅剩 ${item.stock} 件');
      }

      final userRows = await txn.query('users', where: 'id = ?', whereArgs: [req.userId]);
      if (userRows.isEmpty) throw const RedemptionException('用户不存在');
      final user = AppUser.fromMap(userRows.first);
      if (user.points < req.totalCost) {
        throw RedemptionException('用户积分不足，当前余额 ${user.points}');
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final txId = await txn.insert('points_transactions', {
        'user_id': req.userId,
        'amount': -req.totalCost,
        'type': PointsTxType.redeem.name,
        'status': ReviewStatus.approved.name,
        'source': PointsTxSource.admin.name,
        'note': '兑换「${item.name}」x${req.quantity}',
        'operator_id': operatorId,
        'created_at': now,
        'reviewed_at': now,
      });

      await txn.rawUpdate('UPDATE users SET points = points - ? WHERE id = ?', [req.totalCost, req.userId]);
      await txn.rawUpdate('UPDATE items SET stock = stock - ? WHERE id = ?', [req.quantity, req.itemId]);

      await txn.update('redemption_requests', {
        'status': ReviewStatus.approved.name,
        'operator_id': operatorId,
        'reviewed_at': now,
        'points_tx_id': txId,
      }, where: 'id = ?', whereArgs: [requestId]);
    });
    await _db.notifyDataChanged();
  }

  @override
  Future<void> reject(int requestId, int operatorId, {String? reason}) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      final rows = await txn.query('redemption_requests', where: 'id = ?', whereArgs: [requestId]);
      if (rows.isEmpty) throw const RedemptionException('申请不存在');
      final req = RedemptionRequest.fromMap(rows.first);
      if (req.status != ReviewStatus.pending) throw const RedemptionException('该申请已被处理');
      final note = reason?.trim().isEmpty ?? true ? '驳回' : '驳回：${reason!.trim()}';
      await txn.update('redemption_requests', {
        'status': ReviewStatus.rejected.name,
        'operator_id': operatorId,
        'reviewed_at': DateTime.now().millisecondsSinceEpoch,
        'note': [req.note, note].whereType<String>().join(' | '),
      }, where: 'id = ?', whereArgs: [requestId]);
    });
    await _db.notifyDataChanged();
  }
}
