import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppGradients {
  static const homeHeader = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFF2DA), Color(0xFFF3EAE5), Color(0xFFE8F3EF)],
  );

  static const gamificationHero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF075E57), AppColors.primary, Color(0xFF123D3A)],
  );

  static const explore = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.navy, Color(0xFF172846), Color(0xFF213956)],
  );

  static LinearGradient category(Color accent) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent.withValues(alpha: .92), accent.withValues(alpha: .58)],
  );
}
