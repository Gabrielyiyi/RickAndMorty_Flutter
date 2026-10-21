import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const portal = Color(0xFF97CE4C); // verde portal
  static const cyan = Color(0xFF44C8E8);
  static const background = Color(0xFF0E1215);
  static const surface = Color(0xFF181E23);
  static const surfaceHigh = Color(0xFF222A31);

  static const alive = Color(0xFF55CC44);
  static const dead = Color(0xFFE5484D);
  static const unknown = Color(0xFF9E9E9E);

  static Color status(String status) => switch (status) {
        'Alive' => alive,
        'Dead' => dead,
        _ => unknown,
      };
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.portal,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.portal,
      onPrimary: const Color(0xFF10210A),
      secondary: AppColors.cyan,
      surface: AppColors.surface,
    );

    // Tipografía de la plataforma (Roboto en Android, la del sistema en iOS)
    // como base de los estilos propios, para que no pierdan la fuente.
    final type = Typography.material2021(platform: defaultTargetPlatform).white;

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: type.titleLarge!.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceHigh,
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.portal, width: 1.6),
        ),
        errorBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.dead, width: 1.2),
        ),
        focusedErrorBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.dead, width: 1.6),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        errorMaxLines: 2,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: type.labelLarge!.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}
