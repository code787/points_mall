import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../data/models/enums.dart';

class ReviewStatusBadge extends StatelessWidget {
  const ReviewStatusBadge({super.key, required this.status});
  final ReviewStatus status;

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class UserStatusBadge extends StatelessWidget {
  const UserStatusBadge({super.key, required this.status});
  final UserStatus status;

  @override
  Widget build(BuildContext context) {
    final color = userStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class ItemStatusBadge extends StatelessWidget {
  const ItemStatusBadge({super.key, required this.status});
  final ItemStatus status;

  @override
  Widget build(BuildContext context) {
    final color = itemStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class RoleBadge extends StatelessWidget {
  const RoleBadge({super.key, required this.role});
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final color = role == UserRole.admin ? const Color(0xFF3D5AFE) : const Color(0xFF757575);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        role.label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
