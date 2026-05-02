import 'package:flutter/material.dart';

class AppSpacing {
  // Spacing values
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Edge insets shortcuts
  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);

  // Horizontal padding
  static const EdgeInsets horizontalXs = EdgeInsets.symmetric(horizontal: xs);
  static const EdgeInsets horizontalSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets horizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets horizontalLg = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets horizontalXl = EdgeInsets.symmetric(horizontal: xl);

  // Vertical padding
  static const EdgeInsets verticalXs = EdgeInsets.symmetric(vertical: xs);
  static const EdgeInsets verticalSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets verticalMd = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets verticalLg = EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets verticalXl = EdgeInsets.symmetric(vertical: xl);
}

/// App asset paths (kept centralized to avoid typos across the UI).
class AppAssets {
  static const String logo = 'assets/images/Medisom_Logo_1024x1024_transparente.png';
}

/// Border radius constants for consistent rounded corners
class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
}

// =============================================================================
// TEXT STYLE EXTENSIONS
// =============================================================================

/// Extension to add text style utilities to BuildContext
/// Access via context.textStyles
extension TextStyleContext on BuildContext {
  TextTheme get textStyles => Theme.of(this).textTheme;
}

/// Helper methods for common text style modifications
extension TextStyleExtensions on TextStyle {
  /// Make text bold
  TextStyle get bold => copyWith(fontWeight: FontWeight.bold);

  /// Make text semi-bold
  TextStyle get semiBold => copyWith(fontWeight: FontWeight.w600);

  /// Make text medium weight
  TextStyle get medium => copyWith(fontWeight: FontWeight.w500);

  /// Make text normal weight
  TextStyle get normal => copyWith(fontWeight: FontWeight.w400);

  /// Make text light
  TextStyle get light => copyWith(fontWeight: FontWeight.w300);

  /// Add custom color
  TextStyle withColor(Color color) => copyWith(color: color);

  /// Add custom size
  TextStyle withSize(double size) => copyWith(fontSize: size);
}

// =============================================================================
// COLORS
// =============================================================================

/// Modern, neutral color palette for light mode
/// Uses soft grays and blues instead of purple for a contemporary look
class LightModeColors {
  // Primary: Soft blue-gray for a modern, professional look
  static const lightPrimary = Color(0xFF5B7C99);
  static const lightOnPrimary = Color(0xFFFFFFFF);
  static const lightPrimaryContainer = Color(0xFFD8E6F3);
  static const lightOnPrimaryContainer = Color(0xFF1A3A52);

  // Secondary: Complementary gray-blue
  static const lightSecondary = Color(0xFF5C6B7A);
  static const lightOnSecondary = Color(0xFFFFFFFF);

  // Tertiary: Subtle accent color
  static const lightTertiary = Color(0xFF6B7C8C);
  static const lightOnTertiary = Color(0xFFFFFFFF);

  // Error colors
  static const lightError = Color(0xFFBA1A1A);
  static const lightOnError = Color(0xFFFFFFFF);
  static const lightErrorContainer = Color(0xFFFFDAD6);
  static const lightOnErrorContainer = Color(0xFF410002);

  // Surface and background: High contrast for readability
  static const lightSurface = Color(0xFFFBFCFD);
  static const lightOnSurface = Color(0xFF1A1C1E);
  static const lightBackground = Color(0xFFF7F9FA);
  static const lightSurfaceVariant = Color(0xFFE2E8F0);
  static const lightOnSurfaceVariant = Color(0xFF44474E);

  // Outline and shadow
  static const lightOutline = Color(0xFF74777F);
  static const lightShadow = Color(0xFF000000);
  static const lightInversePrimary = Color(0xFFACC7E3);
}

/// Dark mode colors with good contrast
class DarkModeColors {
  // Primary: Lighter blue for dark background
  // Petrol blue / teal (sobrio, alto contraste)
  static const darkPrimary = Color(0xFF2BB3A6);
  static const darkOnPrimary = Color(0xFF061514);
  static const darkPrimaryContainer = Color(0xFF3D5A73);
  static const darkOnPrimaryContainer = Color(0xFFD8E6F3);

  // Secondary
  static const darkSecondary = Color(0xFFBCC7D6);
  static const darkOnSecondary = Color(0xFF2E3842);

  // Tertiary
  static const darkTertiary = Color(0xFFB8C8D8);
  static const darkOnTertiary = Color(0xFF344451);

  // Error colors
  static const darkError = Color(0xFFFFB4AB);
  static const darkOnError = Color(0xFF690005);
  static const darkErrorContainer = Color(0xFF93000A);
  static const darkOnErrorContainer = Color(0xFFFFDAD6);

  // Surface and background: True dark mode
  static const darkSurface = Color(0xFF121416);
  static const darkOnSurface = Color(0xFFE7EDF4);
  static const darkSurfaceVariant = Color(0xFF1B1F24);
  static const darkOnSurfaceVariant = Color(0xFFB8C2CC);

  // Outline and shadow
  static const darkOutline = Color(0xFF8E9099);
  static const darkShadow = Color(0xFF000000);
  static const darkInversePrimary = Color(0xFF5B7C99);
}

/// Font size constants
class FontSizes {
  static const double displayLarge = 57.0;
  static const double displayMedium = 45.0;
  static const double displaySmall = 36.0;
  static const double headlineLarge = 32.0;
  static const double headlineMedium = 28.0;
  static const double headlineSmall = 22.0;
  static const double titleLarge = 20.0;
  static const double titleMedium = 15.0;
  static const double titleSmall = 13.0;
  static const double labelLarge = 13.0;
  static const double labelMedium = 11.0;
  static const double labelSmall = 10.0;
  static const double bodyLarge = 15.0;
  static const double bodyMedium = 13.0;
  static const double bodySmall = 11.5;
}

TextStyle _appTextStyle({double? fontSize, FontWeight? fontWeight, double? letterSpacing, double height = 1.45, Color? color}) => TextStyle(fontSize: fontSize, fontWeight: fontWeight, letterSpacing: letterSpacing, height: height, color: color);

// =============================================================================
// THEMES
// =============================================================================

/// Light theme with modern, neutral aesthetic
ThemeData get lightTheme => ThemeData(
  useMaterial3: true,
  fontFamily: 'Roboto',
  colorScheme: ColorScheme.light(
    primary: LightModeColors.lightPrimary,
    onPrimary: LightModeColors.lightOnPrimary,
    primaryContainer: LightModeColors.lightPrimaryContainer,
    onPrimaryContainer: LightModeColors.lightOnPrimaryContainer,
    secondary: LightModeColors.lightSecondary,
    onSecondary: LightModeColors.lightOnSecondary,
    tertiary: LightModeColors.lightTertiary,
    onTertiary: LightModeColors.lightOnTertiary,
    error: LightModeColors.lightError,
    onError: LightModeColors.lightOnError,
    errorContainer: LightModeColors.lightErrorContainer,
    onErrorContainer: LightModeColors.lightOnErrorContainer,
    surface: LightModeColors.lightSurface,
    onSurface: LightModeColors.lightOnSurface,
    surfaceContainerHighest: LightModeColors.lightSurfaceVariant,
    onSurfaceVariant: LightModeColors.lightOnSurfaceVariant,
    outline: LightModeColors.lightOutline,
    shadow: LightModeColors.lightShadow,
    inversePrimary: LightModeColors.lightInversePrimary,
  ),
  brightness: Brightness.light,
  scaffoldBackgroundColor: LightModeColors.lightBackground,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: LightModeColors.lightOnSurface,
    elevation: 0,
    scrolledUnderElevation: 0,
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(
        color: LightModeColors.lightOutline.withValues(alpha: 0.2),
        width: 1,
      ),
    ),
  ),
  textTheme: _buildTextTheme(Brightness.light),
  inputDecorationTheme: _inputDecorationTheme(Brightness.light),
  elevatedButtonTheme: _elevatedButtonTheme(Brightness.light),
  filledButtonTheme: _filledButtonTheme(Brightness.light),
);

/// Dark theme with good contrast and readability
ThemeData get darkTheme => ThemeData(
  useMaterial3: true,
  fontFamily: 'Roboto',
  colorScheme: ColorScheme.dark(
    primary: DarkModeColors.darkPrimary,
    onPrimary: DarkModeColors.darkOnPrimary,
    primaryContainer: DarkModeColors.darkPrimaryContainer,
    onPrimaryContainer: DarkModeColors.darkOnPrimaryContainer,
    secondary: DarkModeColors.darkSecondary,
    onSecondary: DarkModeColors.darkOnSecondary,
    tertiary: DarkModeColors.darkTertiary,
    onTertiary: DarkModeColors.darkOnTertiary,
    error: DarkModeColors.darkError,
    onError: DarkModeColors.darkOnError,
    errorContainer: DarkModeColors.darkErrorContainer,
    onErrorContainer: DarkModeColors.darkOnErrorContainer,
    surface: DarkModeColors.darkSurface,
    onSurface: DarkModeColors.darkOnSurface,
    surfaceContainerHighest: DarkModeColors.darkSurfaceVariant,
    onSurfaceVariant: DarkModeColors.darkOnSurfaceVariant,
    outline: DarkModeColors.darkOutline,
    shadow: DarkModeColors.darkShadow,
    inversePrimary: DarkModeColors.darkInversePrimary,
  ),
  brightness: Brightness.dark,
  scaffoldBackgroundColor: DarkModeColors.darkSurface,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: DarkModeColors.darkOnSurface,
    elevation: 0,
    scrolledUnderElevation: 0,
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(
        color: DarkModeColors.darkOutline.withValues(alpha: 0.22),
        width: 1,
      ),
    ),
  ),
  textTheme: _buildTextTheme(Brightness.dark),
  inputDecorationTheme: _inputDecorationTheme(Brightness.dark),
  elevatedButtonTheme: _elevatedButtonTheme(Brightness.dark),
  filledButtonTheme: _filledButtonTheme(Brightness.dark),
  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: DarkModeColors.darkSurfaceVariant,
    contentTextStyle: _appTextStyle(color: DarkModeColors.darkOnSurface, fontSize: FontSizes.bodyMedium),
  ),
);

InputDecorationTheme _inputDecorationTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final outline = isDark ? DarkModeColors.darkOutline : LightModeColors.lightOutline;
  final surface = isDark ? DarkModeColors.darkSurfaceVariant : LightModeColors.lightSurfaceVariant;
  final onSurface = isDark ? DarkModeColors.darkOnSurface : LightModeColors.lightOnSurface;
  return InputDecorationTheme(
    filled: true,
    fillColor: surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    hintStyle: _appTextStyle(color: onSurface.withValues(alpha: 0.6)),
    labelStyle: _appTextStyle(color: onSurface.withValues(alpha: 0.85)),
    errorStyle: _appTextStyle(fontSize: FontSizes.bodySmall),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide(color: outline.withValues(alpha: 0.35))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide(color: outline.withValues(alpha: 0.35))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide(color: (isDark ? DarkModeColors.darkPrimary : LightModeColors.lightPrimary), width: 1.4)),
  );
}

ElevatedButtonThemeData _elevatedButtonTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final bg = isDark ? DarkModeColors.darkPrimary : LightModeColors.lightPrimary;
  final fg = isDark ? DarkModeColors.darkOnPrimary : LightModeColors.lightOnPrimary;
  return ElevatedButtonThemeData(
    style: ButtonStyle(
      elevation: const WidgetStatePropertyAll(0),
      backgroundColor: WidgetStatePropertyAll(bg),
      foregroundColor: WidgetStatePropertyAll(fg),
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 18, vertical: 16)),
      shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg))),
      textStyle: WidgetStatePropertyAll(_appTextStyle(fontSize: FontSizes.titleMedium, fontWeight: FontWeight.w600)),
    ),
  );
}

FilledButtonThemeData _filledButtonTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final surface = isDark ? DarkModeColors.darkSurfaceVariant : LightModeColors.lightSurfaceVariant;
  final fg = isDark ? DarkModeColors.darkOnSurface : LightModeColors.lightOnSurface;
  return FilledButtonThemeData(
    style: ButtonStyle(
      elevation: const WidgetStatePropertyAll(0),
      backgroundColor: WidgetStatePropertyAll(surface),
      foregroundColor: WidgetStatePropertyAll(fg),
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
      shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg))),
      textStyle: WidgetStatePropertyAll(_appTextStyle(fontSize: FontSizes.titleSmall, fontWeight: FontWeight.w600)),
    ),
  );
}

/// Build text theme using Inter font family
TextTheme _buildTextTheme(Brightness brightness) {
  return TextTheme(
    displayLarge: _appTextStyle(fontSize: FontSizes.displayLarge, fontWeight: FontWeight.w400, letterSpacing: -0.25, height: 1.12),
    displayMedium: _appTextStyle(fontSize: FontSizes.displayMedium, fontWeight: FontWeight.w400, height: 1.16),
    displaySmall: _appTextStyle(fontSize: FontSizes.displaySmall, fontWeight: FontWeight.w400, height: 1.2),
    headlineLarge: _appTextStyle(fontSize: FontSizes.headlineLarge, fontWeight: FontWeight.w600, letterSpacing: -0.5, height: 1.22),
    headlineMedium: _appTextStyle(fontSize: FontSizes.headlineMedium, fontWeight: FontWeight.w600, height: 1.25),
    headlineSmall: _appTextStyle(fontSize: FontSizes.headlineSmall, fontWeight: FontWeight.w600, height: 1.28),
    titleLarge: _appTextStyle(fontSize: FontSizes.titleLarge, fontWeight: FontWeight.w600, height: 1.3),
    titleMedium: _appTextStyle(fontSize: FontSizes.titleMedium, fontWeight: FontWeight.w500, height: 1.35),
    titleSmall: _appTextStyle(fontSize: FontSizes.titleSmall, fontWeight: FontWeight.w500, height: 1.35),
    labelLarge: _appTextStyle(fontSize: FontSizes.labelLarge, fontWeight: FontWeight.w500, letterSpacing: 0.1, height: 1.35),
    labelMedium: _appTextStyle(fontSize: FontSizes.labelMedium, fontWeight: FontWeight.w500, letterSpacing: 0.5, height: 1.35),
    labelSmall: _appTextStyle(fontSize: FontSizes.labelSmall, fontWeight: FontWeight.w500, letterSpacing: 0.5, height: 1.35),
    bodyLarge: _appTextStyle(fontSize: FontSizes.bodyLarge, fontWeight: FontWeight.w400, letterSpacing: 0.15),
    bodyMedium: _appTextStyle(fontSize: FontSizes.bodyMedium, fontWeight: FontWeight.w400, letterSpacing: 0.25),
    bodySmall: _appTextStyle(fontSize: FontSizes.bodySmall, fontWeight: FontWeight.w400, letterSpacing: 0.4),
  );
}
