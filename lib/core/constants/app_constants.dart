class AppConstants {
  AppConstants._();

  static const String appName = '积分商城';
  static const String dbFileName = 'points_mall.db';
  static const String defaultAdminUsername = 'admin';
  static const String defaultAdminPassword = 'admin123';
  static const String sessionKey = 'current_user_id';

  static const List<String> itemEmojis = [
    '🎁', '🏆', '🎧', '📱', '⌚', '👕', '☕', '📚',
    '🎮', '💄', '🎒', '🧸', '🖱️', '💻', '🔋', '🧴',
  ];

  static const List<ColorValue> itemColors = [
    ColorValue('red', 0xFFE53935),
    ColorValue('orange', 0xFFFB8C00),
    ColorValue('amber', 0xFFFDD835),
    ColorValue('green', 0xFF43A047),
    ColorValue('teal', 0xFF00897B),
    ColorValue('blue', 0xFF1E88E5),
    ColorValue('indigo', 0xFF3949AB),
    ColorValue('purple', 0xFF8E24AA),
    ColorValue('pink', 0xFFD81B60),
    ColorValue('grey', 0xFF757575),
  ];
}

class ColorValue {
  final String name;
  final int value;
  const ColorValue(this.name, this.value);
}
