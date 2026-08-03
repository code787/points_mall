import 'enums.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.username,
    required this.passwordHash,
    required this.displayName,
    required this.role,
    required this.points,
    required this.status,
    required this.createdAt,
  });

  final int id;
  final String username;
  final String passwordHash;
  final String displayName;
  final UserRole role;
  final int points;
  final UserStatus status;
  final DateTime createdAt;

  bool get isAdmin => role == UserRole.admin;
  bool get isActive => status == UserStatus.active;

  AppUser copyWith({
    int? points,
    String? displayName,
    String? passwordHash,
    UserRole? role,
    UserStatus? status,
  }) {
    return AppUser(
      id: id,
      username: username,
      passwordHash: passwordHash ?? this.passwordHash,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      points: points ?? this.points,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }

  factory AppUser.fromMap(Map<String, Object?> map) => AppUser(
        id: map['id'] as int,
        username: map['username'] as String,
        passwordHash: map['password_hash'] as String,
        displayName: map['display_name'] as String,
        role: UserRole.values.byName(map['role'] as String),
        points: map['points'] as int,
        status: UserStatus.values.byName(map['status'] as String),
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'username': username,
        'password_hash': passwordHash,
        'display_name': displayName,
        'role': role.name,
        'points': points,
        'status': status.name,
        'created_at': createdAt.millisecondsSinceEpoch,
      };
}
