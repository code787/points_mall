import '../../core/utils/password.dart';
import '../local/database_helper.dart';
import '../models/app_user.dart';
import '../models/enums.dart';

abstract class UserRepository {
  Future<List<AppUser>> getAll({String? keyword});
  Future<AppUser?> getById(int id);
  Future<AppUser?> getByUsername(String username);
  Future<AppUser> create({
    required String username,
    required String password,
    required String displayName,
    required UserRole role,
    int initialPoints = 0,
  });
  Future<void> update(AppUser user);
  Future<void> setStatus(int id, UserStatus status);
  Future<void> resetPassword(int id, String newPassword);
}

class UserException implements Exception {
  final String message;
  const UserException(this.message);
  @override
  String toString() => message;
}

class LocalUserRepository implements UserRepository {
  LocalUserRepository(this._db);
  final DatabaseHelper _db;

  @override
  Future<List<AppUser>> getAll({String? keyword}) async {
    final db = await _db.database;
    if (keyword == null || keyword.trim().isEmpty) {
      final rows = await db.query('users', orderBy: 'created_at ASC');
      return rows.map(AppUser.fromMap).toList();
    }
    final like = '%${keyword.trim()}%';
    final rows = await db.query(
      'users',
      where: 'username LIKE ? OR display_name LIKE ?',
      whereArgs: [like, like],
      orderBy: 'created_at ASC',
    );
    return rows.map(AppUser.fromMap).toList();
  }

  @override
  Future<AppUser?> getById(int id) async {
    final db = await _db.database;
    final rows = await db.query('users', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return AppUser.fromMap(rows.first);
  }

  @override
  Future<AppUser?> getByUsername(String username) async {
    final db = await _db.database;
    final rows = await db.query('users', where: 'username = ?', whereArgs: [username.trim()], limit: 1);
    if (rows.isEmpty) return null;
    return AppUser.fromMap(rows.first);
  }

  @override
  Future<AppUser> create({
    required String username,
    required String password,
    required String displayName,
    required UserRole role,
    int initialPoints = 0,
  }) async {
    final db = await _db.database;
    final existing = await getByUsername(username);
    if (existing != null) throw const UserException('用户名已存在');
    final id = await db.insert('users', {
      'username': username.trim(),
      'password_hash': hashPassword(password),
      'display_name': displayName.trim(),
      'role': role.name,
      'points': initialPoints,
      'status': UserStatus.active.name,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
    return (await getById(id))!;
  }

  @override
  Future<void> update(AppUser user) async {
    final db = await _db.database;
    await db.update('users', {
      'display_name': user.displayName,
      'role': user.role.name,
      'points': user.points,
      'status': user.status.name,
    }, where: 'id = ?', whereArgs: [user.id]);
  }

  @override
  Future<void> setStatus(int id, UserStatus status) async {
    final db = await _db.database;
    await db.update('users', {'status': status.name}, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> resetPassword(int id, String newPassword) async {
    final db = await _db.database;
    await db.update('users', {'password_hash': hashPassword(newPassword)}, where: 'id = ?', whereArgs: [id]);
  }
}
