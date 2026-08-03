import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/app_user.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/user_repository.dart';
import 'repository_providers.dart';

class AuthController extends ChangeNotifier {
  AuthController({
    required this.authRepository,
    required this.userRepository,
  });

  final AuthRepository authRepository;
  final UserRepository userRepository;

  AppUser? _user;
  bool _ready = false;

  AppUser? get user => _user;
  bool get isReady => _ready;
  bool get isLoggedIn => _user != null;
  bool get isAdmin => _user?.isAdmin ?? false;

  Future<void> init() async {
    try {
      await authRepository.ensureDefaultAdmin();
      _user = await authRepository.restoreSession();
    } catch (_) {
      _user = null;
    } finally {
      _ready = true;
      notifyListeners();
    }
  }

  Future<String?> login(String username, String password) async {
    try {
      final user = await authRepository.login(username, password);
      _user = user;
      _ready = true;
      notifyListeners();
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (_) {
      return '登录失败，请重试';
    }
  }

  Future<void> logout() async {
    await authRepository.logout();
    _user = null;
    notifyListeners();
  }

  Future<void> refreshUser() async {
    final id = _user?.id;
    if (id == null) return;
    _user = await userRepository.getById(id);
    notifyListeners();
  }
}

final authControllerProvider = ChangeNotifierProvider<AuthController>((ref) {
  final controller = AuthController(
    authRepository: ref.watch(authRepoProvider),
    userRepository: ref.watch(userRepoProvider),
  );
  controller.init();
  return controller;
});

final currentUserProvider = Provider<AppUser?>((ref) => ref.watch(authControllerProvider).user);
