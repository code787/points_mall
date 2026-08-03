import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/password.dart';
import '../local/database_helper.dart';
import '../models/app_user.dart';
import '../models/enums.dart';
import 'user_repository.dart';

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  @override
  String toString() => message;
}

class AuthRepository {
  AuthRepository({required this.userRepository});
  final UserRepository userRepository;

  Future<void> ensureDefaultAdmin() async {
    final db = await DatabaseHelper.instance.database;
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM users')) ?? 0;
    if (count == 0) {
      await userRepository.create(
        username: AppConstants.defaultAdminUsername,
        password: AppConstants.defaultAdminPassword,
        displayName: '系统管理员',
        role: UserRole.admin,
      );
    }
  }

  Future<AppUser?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(AppConstants.sessionKey);
    if (id == null) return null;
    final user = await userRepository.getById(id);
    if (user == null || !user.isActive) {
      await prefs.remove(AppConstants.sessionKey);
      return null;
    }
    return user;
  }

  Future<AppUser> login(String username, String password) async {
    await ensureDefaultAdmin();
    final user = await userRepository.getByUsername(username);
    if (user == null) throw const AuthException('用户名或密码错误');
    if (!verifyPassword(password, user.passwordHash)) {
      throw const AuthException('用户名或密码错误');
    }
    if (!user.isActive) throw const AuthException('账号已被停用，请联系管理员');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.sessionKey, user.id);
    return user;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.sessionKey);
  }
}
