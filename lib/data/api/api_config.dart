/// 预留的 API 配置与示例。
///
/// 当前系统为「本地存储」模式（sqflite），所有数据保存在本机。
/// 后续接入后端时：
///   1. 在 [ApiConfig] 中配置服务器地址；
///   2. 在 `data/repositories` 中新增 `ApiUserRepository` 等实现，
///      实现与本地实现相同的接口（见 `user_repository.dart` 等文件）；
///   3. 在 `providers/repository_providers.dart` 中把 provider 换成远程实现，
///      上层界面代码无需改动。
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = 'https://api.example.com';
  static const Duration timeout = Duration(seconds: 15);

  static String get pointsPath => '/api/v1/points';
  static String get itemsPath => '/api/v1/items';
  static String get redemptionsPath => '/api/v1/redemptions';
  static String get usersPath => '/api/v1/users';
  static String get authPath => '/api/v1/auth';
  static String get statsPath => '/api/v1/stats';
}
