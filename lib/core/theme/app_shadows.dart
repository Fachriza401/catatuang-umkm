import 'package:flutter/material.dart';

abstract final class AppShadows {
  static const soft = <BoxShadow>[
    BoxShadow(color: Color(0x0A0F172A), blurRadius: 12, offset: Offset(0, 4)),
  ];

  static const card = <BoxShadow>[
    BoxShadow(color: Color(0x0F0F172A), blurRadius: 24, offset: Offset(0, 8)),
  ];

  static const floating = <BoxShadow>[
    BoxShadow(color: Color(0x1F0F172A), blurRadius: 32, offset: Offset(0, 16)),
  ];

  static List<BoxShadow> primaryGlow(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.28),
      blurRadius: 28,
      offset: const Offset(0, 12),
    ),
  ];
}
