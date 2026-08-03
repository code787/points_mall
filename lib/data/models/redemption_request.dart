import 'enums.dart';

class RedemptionRequest {
  const RedemptionRequest({
    required this.id,
    required this.userId,
    required this.itemId,
    required this.quantity,
    required this.totalCost,
    required this.status,
    this.note,
    this.operatorId,
    required this.createdAt,
    this.reviewedAt,
    this.pointsTxId,
    this.userName,
    this.itemName,
    this.itemEmoji,
    this.itemColor,
  });

  final int id;
  final int userId;
  final int itemId;
  final int quantity;
  final int totalCost;
  final ReviewStatus status;
  final String? note;
  final int? operatorId;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final int? pointsTxId;
  final String? userName;
  final String? itemName;
  final String? itemEmoji;
  final int? itemColor;

  factory RedemptionRequest.fromMap(Map<String, Object?> map) => RedemptionRequest(
        id: map['id'] as int,
        userId: map['user_id'] as int,
        itemId: map['item_id'] as int,
        quantity: map['quantity'] as int,
        totalCost: map['total_cost'] as int,
        status: ReviewStatus.values.byName(map['status'] as String),
        note: map['note'] as String?,
        operatorId: map['operator_id'] as int?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
        reviewedAt: map['reviewed_at'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(map['reviewed_at'] as int),
        pointsTxId: map['points_tx_id'] as int?,
        userName: map['user_name'] as String?,
        itemName: map['item_name'] as String?,
        itemEmoji: map['item_emoji'] as String?,
        itemColor: map['item_color'] as int?,
      );
}
