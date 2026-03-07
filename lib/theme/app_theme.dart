import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  ThemeNotifier() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('themeMode') ?? 'system';
    _themeMode = _fromString(mode);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', _toString(mode));
    notifyListeners();
  }

  static ThemeMode _fromString(String s) {
    switch (s) {
      case 'light': return ThemeMode.light;
      case 'dark': return ThemeMode.dark;
      default: return ThemeMode.system;
    }
  }

  static String _toString(ThemeMode m) {
    switch (m) {
      case ThemeMode.light: return 'light';
      case ThemeMode.dark: return 'dark';
      case ThemeMode.system: return 'system';
    }
  }
}

class AppTheme {
  // ── Light palette ──
  static const Color primary = Color(0xFF0061A4);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFD1E4FF);
  static const Color onPrimaryContainer = Color(0xFF001D36);

  static const Color secondary = Color(0xFF535F70);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFD7E3F7);
  static const Color onSecondaryContainer = Color(0xFF101C2B);

  static const Color tertiary = Color(0xFF6B5778);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFF2DAFF);
  static const Color onTertiaryContainer = Color(0xFF251431);

  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF410002);

  static const Color surface = Color(0xFFF8F9FF);
  static const Color surfaceVariant = Color(0xFFDFE2EB);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF2F3FA);
  static const Color surfaceContainer = Color(0xFFECEEF5);
  static const Color surfaceContainerHigh = Color(0xFFE6E8EF);
  static const Color surfaceContainerHighest = Color(0xFFE1E2E9);
  static const Color surfaceTint = Color(0xFF0061A4);

  static const Color onSurface = Color(0xFF191C20);
  static const Color onSurfaceVariant = Color(0xFF43474E);
  static const Color outline = Color(0xFF73777F);
  static const Color outlineVariant = Color(0xFFC3C7CF);

  static const Color inverseSurface = Color(0xFF2E3036);
  static const Color inverseOnSurface = Color(0xFFEFF0F7);
  static const Color inversePrimary = Color(0xFF9ECAFF);

  static const Color scrim = Color(0xFF000000);
  static const Color tonal1 = Color(0xFFE8F1FF);

  static List<BoxShadow> elevation(int level) {
    if (level == 0) return [];
    final a06 = primary.withValues(alpha: 0.06);
    final a08 = primary.withValues(alpha: 0.08);
    final a10 = primary.withValues(alpha: 0.10);
    final a12 = primary.withValues(alpha: 0.12);
    final s12 = scrim.withValues(alpha: 0.12);
    final s10 = scrim.withValues(alpha: 0.10);
    switch (level) {
      case 1: return [BoxShadow(offset: const Offset(0, 1), blurRadius: 2, color: s12), BoxShadow(offset: const Offset(0, 1), blurRadius: 3, color: a06)];
      case 2: return [BoxShadow(offset: const Offset(0, 1), blurRadius: 2, color: s10), BoxShadow(offset: const Offset(0, 2), blurRadius: 6, color: a08)];
      case 3: return [BoxShadow(offset: const Offset(0, 1), blurRadius: 3, color: s10), BoxShadow(offset: const Offset(0, 4), blurRadius: 8, color: a10)];
      case 4: return [BoxShadow(offset: const Offset(0, 2), blurRadius: 3, color: s10), BoxShadow(offset: const Offset(0, 6), blurRadius: 10, color: a10)];
      case 5: return [BoxShadow(offset: const Offset(0, 4), blurRadius: 4, color: s10), BoxShadow(offset: const Offset(0, 8), blurRadius: 12, color: a12)];
      default: return [];
    }
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: surface,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: primary, onPrimary: onPrimary,
        primaryContainer: primaryContainer, onPrimaryContainer: onPrimaryContainer,
        secondary: secondary, onSecondary: onSecondary,
        secondaryContainer: secondaryContainer, onSecondaryContainer: onSecondaryContainer,
        tertiary: tertiary, onTertiary: onTertiary,
        tertiaryContainer: tertiaryContainer, onTertiaryContainer: onTertiaryContainer,
        error: error, onError: onError,
        errorContainer: errorContainer, onErrorContainer: onErrorContainer,
        surface: surface, onSurface: onSurface,
        surfaceContainerHighest: surfaceContainerHighest,
        onSurfaceVariant: onSurfaceVariant,
        outline: outline, outlineVariant: outlineVariant,
        inverseSurface: inverseSurface, onInverseSurface: inverseOnSurface,
        inversePrimary: inversePrimary, scrim: scrim,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontWeight: FontWeight.w400, color: onSurface, fontSize: 28, letterSpacing: -0.5),
        bodyLarge: TextStyle(fontWeight: FontWeight.w500, color: onSurface, fontSize: 14, letterSpacing: 0.1),
        bodyMedium: TextStyle(fontWeight: FontWeight.w400, color: onSurfaceVariant, fontSize: 13),
        labelLarge: TextStyle(fontWeight: FontWeight.w500, color: onSurfaceVariant, fontSize: 11, letterSpacing: 0.8),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF111318),
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: Color(0xFF9ECAFF), onPrimary: Color(0xFF003258),
        primaryContainer: Color(0xFF00497D), onPrimaryContainer: Color(0xFFD1E4FF),
        secondary: Color(0xFFBBC7DB), onSecondary: Color(0xFF253140),
        secondaryContainer: Color(0xFF3B4858), onSecondaryContainer: Color(0xFFD7E3F7),
        tertiary: Color(0xFFD6BEE4), onTertiary: Color(0xFF3B2948),
        tertiaryContainer: Color(0xFF523F5F), onTertiaryContainer: Color(0xFFF2DAFF),
        error: Color(0xFFFFB4AB), onError: Color(0xFF690005),
        errorContainer: Color(0xFF93000A), onErrorContainer: Color(0xFFFFDAD6),
        surface: Color(0xFF111318), onSurface: Color(0xFFE1E2E9),
        surfaceContainerHighest: Color(0xFF33353B),
        onSurfaceVariant: Color(0xFFC3C7CF),
        outline: Color(0xFF8D9199), outlineVariant: Color(0xFF43474E),
        inverseSurface: Color(0xFFE1E2E9), onInverseSurface: Color(0xFF2E3036),
        inversePrimary: Color(0xFF0061A4), scrim: Color(0xFF000000),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontWeight: FontWeight.w400, color: Color(0xFFE1E2E9), fontSize: 28, letterSpacing: -0.5),
        bodyLarge: TextStyle(fontWeight: FontWeight.w500, color: Color(0xFFE1E2E9), fontSize: 14, letterSpacing: 0.1),
        bodyMedium: TextStyle(fontWeight: FontWeight.w400, color: Color(0xFFC3C7CF), fontSize: 13),
        labelLarge: TextStyle(fontWeight: FontWeight.w500, color: Color(0xFFC3C7CF), fontSize: 11, letterSpacing: 0.8),
      ),
    );
  }

  // Legacy getter for backward compat
  static ThemeData get themeData => lightTheme;
}
