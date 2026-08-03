import '../local/database_helper.dart';
import '../models/enums.dart';
import '../models/points_transaction.dart';

abstract class PointsRepository {
  Future<List<PointsTransaction>> getAll({int? userId, ReviewStatus? status});
  Future<PointsTransaction?> getById(int id);
  Future<PointsTransaction> createRequest({
    required int userId,
    required int amount,
    String? note,
  });
  Future<void> approve(int txId, int operatorId);
  Future<void> reject(int txId, int operatorId, {String? reason});
}

class PointsException implements Exception {
  final String message;
  const PointsException(this.message);
  @override
  String toString() => message;
}

class LocalPointsRepository implements PointsRepository {
  LocalPointsRepository(this._db);
  final DatabaseHelper _db;

  @override
  Future<PointsTransaction?> getById(int id) async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      '''
      SELECT pts.*, u.display_name AS user_name
      FROM points_transactions pts
      LEFT JOIN users u ON u.id = pts.user_id
      WHERE pts.id = ?
      ''',
      [id],
    );
    if (rows.isEmpty) return null;
    return PointsTransaction.fromMap(rows.first);
  }

  @override
  Future<List<PointsTransaction>> getAll({int? userId, ReviewStatus? status}) async {
    final db = await _db.database;
    final where = <String>[];
    final args = <Object?>[];
    if (userId != null) {
      where.add('pts.user_id = ?');
      args.add(userId);
    }
    if (status != null) {
      where.add('pts.status = ?');
      args.add(status.name);
    }
    var sql = '''
      SELECT pts.*, u.display_name AS user_name
      FROM points_transactions pts
      LEFT JOIN users u ON u.id = pts.user_id
    ''';
    if (where.isNotEmpty) sql += ' WHERE ${where.join(' AND ')}';
    sql += ' ORDER BY pts.created_at DESC, pts.id DESC';
    final rows = await db.rawQuery(sql, args);
    return rows.map(PointsTransaction.fromMap).toList();
  }

  @override
  Future<PointsTransaction> createRequest({
    required int userId,
    required int amount,
    String? note,
  }) async {
    if (amount == 0) throw const PointsException('积分变动不能为 0');
    final db = await _db.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = await db.insert('points_transactions', {
      'user_id': userId,
      'amount': amount,
      'type': amount > 0 ? PointsTxType.earn.name : PointsTxType.deduct.name,
      'status': ReviewStatus.pending.name,
      'note': note?.trim().isEmpty ?? true ? null : note!.trim(),
      'created_at': now,
    });
    return (await getById(id))!;
  }

  @override
  Future<void> approve(int txId, int operatorId) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      final rows = await txn.query('points_transactions', where: 'id = ?', whereArgs: [txId]);
      if (rows.isEmpty) throw const PointsException('记录不存在');
      final tx = PointsTransaction.fromMap(rows.first);
      if (tx.status != ReviewStatus.pending) throw const PointsException('该记录已被处理');
      final userRows = await txn.query('users', where: 'id = ?', whereArgs: [tx.userId]);
      if (userRows.isEmpty) throw const PointsException('关联用户不存在');
      final currentPoints = userRows.first['points'] as int;
      if (currentPoints + tx.amount < 0) {
        throw PointsException('用户当前积分 $currentPoints，扣减后为负，无法通过');
      }
      await txn.rawUpdate('UPDATE users SET points = points + ? WHERE id = ?', [tx.amount, tx.userId]);
      await txn.update('points_transactions', {
        'status': ReviewStatus.approved.name,
        'operator_id': operatorId,
        'reviewed_at': DateTime.now().millisecondsSinceEpoch,
      }, where: 'id = ?', whereArgs: [txId]);
    });
  }

  @override
  Future<void> reject(int txId, int operatorId, {String? reason}) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      final rows = await txn.query('points_transactions', where: 'id = ?', whereArgs: [txId]);
      if (rows.isEmpty) throw const PointsException('记录不存在');
      final tx = PointsTransaction.fromMap(rows.first);
      if (tx.status != ReviewStatus.pending) throw const PointsException('该记录已被处理');
      final note = reason?.trim().isEmpty ?? true
          ? '驳回'
          : '驳回：${reason!.trim()}';
      await txn.update('points_transactions', {
        'status': ReviewStatus.rejected.name,
        'operator_id': operatorId,
        'reviewed_at': DateTime.now().millisecondsSinceEpoch,
        'note': [tx.note, note].whereType<String>().join(' | '),
      }, where: 'id = ?', whereArgs: [txId]);
    });
  }
}
