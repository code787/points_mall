enum UserRole { admin, user }

enum UserStatus { active, disabled }

enum ItemStatus { active, inactive }

enum PointsTxType { earn, deduct, redeem }

enum ReviewStatus { pending, approved, rejected }

extension UserRoleX on UserRole {
  String get label => switch (this) {
        UserRole.admin => '管理员',
        UserRole.user => '普通用户',
      };
}

extension UserStatusX on UserStatus {
  String get label => switch (this) {
        UserStatus.active => '启用',
        UserStatus.disabled => '停用',
      };
}

extension ItemStatusX on ItemStatus {
  String get label => switch (this) {
        ItemStatus.active => '上架',
        ItemStatus.inactive => '下架',
      };
}

extension PointsTxTypeX on PointsTxType {
  String get label => switch (this) {
        PointsTxType.earn => '积分奖励',
        PointsTxType.deduct => '积分扣减',
        PointsTxType.redeem => '兑换消费',
      };
}

extension ReviewStatusX on ReviewStatus {
  String get label => switch (this) {
        ReviewStatus.pending => '待审核',
        ReviewStatus.approved => '已通过',
        ReviewStatus.rejected => '已驳回',
      };
}
