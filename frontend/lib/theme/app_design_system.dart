import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFFF4B400);
  static const Color secondary = Color(0xFFF8C84B);
  static const Color background = Color.fromARGB(255, 221, 230, 248);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color border = Color(0xFFE5E7EB);
}

class AppRadii {
  AppRadii._();

  static const double card = 24;
  static const double button = 20;
  static const double input = 18;
}

class AppSpacing {
  AppSpacing._();

  static const double screenHorizontal = 24;
  static const double section = 24;
  static const double cardPadding = 16;
  static const double small = 8;
  static const double medium = 12;
  static const double large = 16;
}

class AppShadows {
  AppShadows._();

  static const List<BoxShadow> soft = [
    BoxShadow(
      color: Color.fromRGBO(17, 24, 39, 0.05),
      blurRadius: 12,
      offset: Offset(0, 6),
    ),
  ];
}

class AppCopy {
  AppCopy._();

  static const String appName = 'Raices';
  static const String appTagline =
      'No busques propiedades. Define lo que necesitas y Raices encuentra matches por ti.';
}
