import 'package:flutter/material.dart';

import '../../data/models/enums.dart';

class AppTheme {
  AppTheme._();

  static const Color seed = Color(0xFF3D5AFE);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        scaffoldBackgroundColor: const Color(0xFFF5F6FA),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          backgroundColor: Color(0xFFF5F6FA),
          scrolledUnderElevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: seed, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        dividerTheme: const DividerThemeData(color: Color(0xFFEDEFF4), space: 1),
      );
}

Color statusColor(ReviewStatus status) => switch (status) {
      ReviewStatus.pending => const Color(0xFFFB8C00),
      ReviewStatus.approved => const Color(0xFF43A047),
      ReviewStatus.rejected => const Color(0xFFE53935),
    };

Color userStatusColor(UserStatus status) =>
    status == UserStatus.active ? const Color(0xFF43A047) : const Color(0xFF9E9E9E);

Color itemStatusColor(ItemStatus status) =>
    status == ItemStatus.active ? const Color(0xFF43A047) : const Color(0xFF9E9E9E);
