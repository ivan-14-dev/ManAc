import 'package:flutter/material.dart';
// Use default system fonts for offline compatibility
// import 'package:google_fonts/google_fonts.dart';

/// App Theme Configuration - WhatsApp Style
/// Clean, modern design with teal/green accent like WhatsApp
class AppTheme {
  // Primary Colors - Green
  static const Color primaryOrange = Color(0xFF00A884);
  static const Color primaryOrangeLight = Color(0xFF25D366);
  static const Color primaryOrangeDark = Color(0xFF00897B);
  
  // Secondary Colors - Same as primary for style
  static const Color primaryBlue = Color(0xFF00A884);
  static const Color primaryBlueLight = Color(0xFF25D366);
  static const Color primaryBlueDark = Color(0xFF00897B);
  
  // Accent Colors
  static const Color accentCyan = Color(0xFF00BCD4);
  static const Color accentTeal = Color(0xFF009688);
  
  // Neutral Colors - Light Mode (style)
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF7F8FA);
  static const Color cardLight = Color(0xFFFFFFFF);
  
  // Neutral Colors - Dark Mode (style)
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color cardDark = Color(0xFF2D2D2D);
  
  // Text Colors
  static const Color textPrimaryLight = Color(0xFF212121);
  static const Color textSecondaryLight = Color(0xFF667781);
  static const Color textPrimaryDark = Color(0xFFE8E8E8);
  static const Color textSecondaryDark = Color(0xFF999999);
  
  // Status Colors
  static const Color success = Color(0xFF25D366);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFEF5350);
  static const Color info = Color(0xFF00A884);

  // Gradients - Simple solid colors like WhatsApp
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryOrange, primaryOrangeLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient blueGradient = LinearGradient(
    colors: [primaryOrange, primaryOrangeLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient orangeBlueGradient = LinearGradient(
    colors: [primaryOrange, primaryOrangeDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Theme-aware solid color for login/splash screens
  static Color getLoginColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return primaryOrangeDark;
    }
    return primaryOrange;
  }

  // Legacy gradient method for compatibility
  static LinearGradient getLoginGradient(BuildContext context) {
    final color = getLoginColor(context);
    return LinearGradient(
      colors: [color, color],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  // Light Theme -  Style
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // Color Scheme - Green
      colorScheme: ColorScheme.light(
        primary: primaryOrange,
        onPrimary: Colors.white,
        secondary: primaryBlue,
        onSecondary: Colors.white,
        tertiary: accentCyan,
        surface: surfaceLight,
        onSurface: textPrimaryLight,
        error: error,
        onError: Colors.white,
      ),
      
      // Scaffold Background
      scaffoldBackgroundColor: backgroundLight,
      
      // AppBar Theme - style
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryOrange,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: cardLight,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryOrange,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      
      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryOrange,
          side: const BorderSide(color: primaryOrange),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryOrange,
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryOrange, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryOrange,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryOrange,
        unselectedItemColor: textSecondaryLight,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      
      // Tab Bar Theme
      tabBarTheme: const TabBarThemeData(
        labelColor: primaryOrange,
        unselectedLabelColor: textSecondaryLight,
        indicatorColor: primaryOrange,
      ),
      
      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: surfaceLight,
        selectedColor: primaryOrange.withOpacity(0.2),
        labelStyle: const TextStyle(color: textPrimaryLight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      
      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: cardLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimaryLight,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      
      // Divider Theme
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade200,
        thickness: 1,
      ),
      
      // List Tile Theme
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      
      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryOrange;
          }
          return Colors.grey;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryOrangeLight.withOpacity(0.5);
          }
          return Colors.grey.shade300;
        }),
      ),
      
      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryOrange;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      
      // Radio Theme
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryOrange;
          }
          return Colors.grey;
        }),
      ),
      
      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryOrange,
      ),
      
      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: textPrimaryLight),
        displayMedium: TextStyle(color: textPrimaryLight),
        displaySmall: TextStyle(color: textPrimaryLight),
        headlineLarge: TextStyle(color: textPrimaryLight),
        headlineMedium: TextStyle(color: textPrimaryLight),
        headlineSmall: TextStyle(color: textPrimaryLight),
        titleLarge: TextStyle(color: textPrimaryLight),
        titleMedium: TextStyle(color: textPrimaryLight),
        titleSmall: TextStyle(color: textPrimaryLight),
        bodyLarge: TextStyle(color: textPrimaryLight),
        bodyMedium: TextStyle(color: textPrimaryLight),
        bodySmall: TextStyle(color: textSecondaryLight),
        labelLarge: TextStyle(color: textPrimaryLight),
        labelMedium: TextStyle(color: textPrimaryLight),
        labelSmall: TextStyle(color: textSecondaryLight),
      ),
    );
  }

  // Dark Theme - Dark Style
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // Color Scheme - Green in Dark
      colorScheme: ColorScheme.dark(
        primary: primaryOrange,
        onPrimary: Colors.white,
        secondary: primaryBlue,
        onSecondary: Colors.white,
        tertiary: accentCyan,
        surface: surfaceDark,
        onSurface: textPrimaryDark,
        error: error,
        onError: Colors.white,
      ),
      
      // Scaffold Background
      scaffoldBackgroundColor: backgroundDark,
      
      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceDark,
        foregroundColor: textPrimaryDark,
        elevation: 0,
        centerTitle: true,
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryOrange,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      
      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryOrange,
          side: const BorderSide(color: primaryOrange),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryOrange,
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryOrange, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryOrange,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceDark,
        selectedItemColor: primaryOrange,
        unselectedItemColor: textSecondaryDark,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      
      // Tab Bar Theme
      tabBarTheme: const TabBarThemeData(
        labelColor: primaryOrange,
        unselectedLabelColor: textSecondaryDark,
        indicatorColor: primaryOrange,
      ),
      
      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: cardDark,
        selectedColor: primaryOrange.withOpacity(0.2),
        labelStyle: const TextStyle(color: textPrimaryDark),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      
      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardDark,
        contentTextStyle: const TextStyle(color: textPrimaryDark),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      
      // Divider Theme
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade800,
        thickness: 1,
      ),
      
      // List Tile Theme
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      
      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryOrange;
          }
          return Colors.grey;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryOrangeLight.withOpacity(0.5);
          }
          return Colors.grey.shade700;
        }),
      ),
      
      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryOrange;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      
      // Radio Theme
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryOrange;
          }
          return Colors.grey;
        }),
      ),
      
      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryOrange,
      ),
      
      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: textPrimaryDark),
        displayMedium: TextStyle(color: textPrimaryDark),
        displaySmall: TextStyle(color: textPrimaryDark),
        headlineLarge: TextStyle(color: textPrimaryDark),
        headlineMedium: TextStyle(color: textPrimaryDark),
        headlineSmall: TextStyle(color: textPrimaryDark),
        titleLarge: TextStyle(color: textPrimaryDark),
        titleMedium: TextStyle(color: textPrimaryDark),
        titleSmall: TextStyle(color: textPrimaryDark),
        bodyLarge: TextStyle(color: textPrimaryDark),
        bodyMedium: TextStyle(color: textPrimaryDark),
        bodySmall: TextStyle(color: textSecondaryDark),
        labelLarge: TextStyle(color: textPrimaryDark),
        labelMedium: TextStyle(color: textPrimaryDark),
        labelSmall: TextStyle(color: textSecondaryDark),
      ),
    );
  }
}
