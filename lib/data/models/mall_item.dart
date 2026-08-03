import 'enums.dart';

class MallItem {
  const MallItem({
    required this.id,
    required this.name,
    required this.description,
    required this.pointsCost,
    required this.stock,
    required this.emoji,
    required this.color,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String name;
  final String description;
  final int pointsCost;
  final int stock;
  final String emoji;
  final int color;
  final ItemStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isActive => status == ItemStatus.active;

  factory MallItem.fromMap(Map<String, Object?> map) => MallItem(
        id: map['id'] as int,
        name: map['name'] as String,
        description: (map['description'] as String?) ?? '',
        pointsCost: map['points_cost'] as int,
        stock: map['stock'] as int,
        emoji: (map['emoji'] as String?) ?? '🎁',
        color: (map['color'] as int?) ?? 0xFF1E88E5,
        status: ItemStatus.values.byName(map['status'] as String),
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'points_cost': pointsCost,
        'stock': stock,
        'emoji': emoji,
        'color': color,
        'status': status.name,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };
}
