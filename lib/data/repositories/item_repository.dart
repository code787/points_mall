import '../local/database_helper.dart';
import '../models/enums.dart';
import '../models/mall_item.dart';

abstract class ItemRepository {
  Future<List<MallItem>> getAll({bool includeInactive = true});
  Future<MallItem?> getById(int id);
  Future<MallItem> create({
    required String name,
    required String description,
    required int pointsCost,
    required int stock,
    required String emoji,
    required int color,
  });
  Future<void> update(MallItem item);
  Future<void> setStatus(int id, ItemStatus status);
  Future<void> adjustStock(int id, int delta);
}

class ItemException implements Exception {
  final String message;
  const ItemException(this.message);
  @override
  String toString() => message;
}

class LocalItemRepository implements ItemRepository {
  LocalItemRepository(this._db);
  final DatabaseHelper _db;

  @override
  Future<List<MallItem>> getAll({bool includeInactive = true}) async {
    final db = await _db.database;
    final rows = await db.query(
      'items',
      where: includeInactive ? null : "status = 'active'",
      orderBy: 'created_at DESC',
    );
    return rows.map(MallItem.fromMap).toList();
  }

  @override
  Future<MallItem?> getById(int id) async {
    final db = await _db.database;
    final rows = await db.query('items', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return MallItem.fromMap(rows.first);
  }

  @override
  Future<MallItem> create({
    required String name,
    required String description,
    required int pointsCost,
    required int stock,
    required String emoji,
    required int color,
  }) async {
    if (name.trim().isEmpty) throw const ItemException('请输入物品名称');
    if (pointsCost <= 0) throw const ItemException('兑换积分需大于 0');
    if (stock < 0) throw const ItemException('库存不能为负');
    final db = await _db.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = await db.insert('items', {
      'name': name.trim(),
      'description': description.trim(),
      'points_cost': pointsCost,
      'stock': stock,
      'emoji': emoji,
      'color': color,
      'status': ItemStatus.active.name,
      'created_at': now,
      'updated_at': now,
    });
    return (await getById(id))!;
  }

  @override
  Future<void> update(MallItem item) async {
    if (item.pointsCost <= 0) throw const ItemException('兑换积分需大于 0');
    if (item.stock < 0) throw const ItemException('库存不能为负');
    final db = await _db.database;
    await db.update('items', {
      'name': item.name,
      'description': item.description,
      'points_cost': item.pointsCost,
      'stock': item.stock,
      'emoji': item.emoji,
      'color': item.color,
      'status': item.status.name,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    }, where: 'id = ?', whereArgs: [item.id]);
  }

  @override
  Future<void> setStatus(int id, ItemStatus status) async {
    final db = await _db.database;
    await db.update('items', {
      'status': status.name,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    }, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> adjustStock(int id, int delta) async {
    final db = await _db.database;
    await db.rawUpdate('UPDATE items SET stock = stock + ?, updated_at = ? WHERE id = ?',
        [delta, DateTime.now().millisecondsSinceEpoch, id]);
  }
}
