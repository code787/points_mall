import 'enums.dart';

class PointsTransaction {
  const PointsTransaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.status,
    this.note,
    this.operatorId,
    required this.createdAt,
    this.reviewedAt,
    this.userName,
  });

  final int id;
  final int userId;
  final int amount;
  final PointsTxType type;
  final ReviewStatus status;
  final String? note;
  final int? operatorId;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? userName;

  PointsTransaction copyWith({ReviewStatus? status, DateTime? reviewedAt, int? operatorId}) {
    return PointsTransaction(
      id: id,
      userId: userId,
      amount: amount,
      type: type,
      status: status ?? this.status,
      note: note,
      operatorId: operatorId ?? this.operatorId,
      createdAt: createdAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      userName: userName,
    );
  }

  factory PointsTransaction.fromMap(Map<String, Object?> map) => PointsTransaction(
        id: map['id'] as int,
        userId: map['user_id'] as int,
        amount: map['amount'] as int,
        type: PointsTxType.values.byName(map['type'] as String),
        status: ReviewStatus.values.byName(map['status'] as String),
        note: map['note'] as String?,
        operatorId: map['operator_id'] as int?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
        reviewedAt: map['reviewed_at'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(map['reviewed_at'] as int),
        userName: map['user_name'] as String?,
      );
}
