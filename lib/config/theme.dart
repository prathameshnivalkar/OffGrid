import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';

/// Application theme configuration
class AppTheme {
  // Color scheme
  static const Color primaryColor = Color(0xFF2196F3); // Blue
  static const Color primaryVariant = Color(0xFF1976D2); // Dark Blue
  static const Color secondaryColor = Color(0xFF03DAC6); // Teal
  static const Color secondaryVariant = Color(0xFF018786); // Dark Teal
  static const Color errorColor = Color(0xFFB00020); // Red
  static const Color surfaceColor = Color(0xFFFFFFFF); // White
  static const Color backgroundColor = Color(0xFFF5F5F5); // Light Grey
  
  // Dark theme colors
  static const Color darkPrimaryColor = Color(0xFF90CAF9); // Light Blue
  static const Color darkSurfaceColor = Color(0xFF121212); // Dark Grey
  static const Color darkBackgroundColor = Color(0xFF000000); // Black
  
  // Mesh network specific colors
  static const Color onlineColor = Color(0xFF4CAF50); // Green
  static const Color offlineColor = Color(0xFF9E9E9E); // Grey
  static const Color connectingColor = Color(0xFFFF9800); // Orange
  static const Color errorConnectionColor = Color(0xFFFF5722); // Deep Orange
  
  // Message bubble colors
  static const Color sentMessageColor = Color(0xFF2196F3); // Blue
  static const Color receivedMessageColor = Color(0xFFE0E0E0); // Light Grey
  static const Color darkSentMessageColor = Color(0xFF1976D2); // Dark Blue
  static const Color darkReceivedMessageColor = Color(0xFF424242); // Dark Grey
  
  /// Light theme configuration
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
        surface: surfaceColor,
      ),
      
      // App Bar Theme
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      
      // Card Theme
      cardTheme: const CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppConstants.borderRadius)),
        ),
        margin: EdgeInsets.symmetric(
          horizontal: AppConstants.defaultPadding,
          vertical: AppConstants.smallPadding,
        ),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.largePadding,
            vertical: AppConstants.defaultPadding,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.defaultPadding,
            vertical: AppConstants.smallPadding,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        contentPadding: const EdgeInsets.all(AppConstants.defaultPadding),
      ),
      
      // List Tile Theme
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppConstants.defaultPadding,
          vertical: AppConstants.smallPadding,
        ),
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        elevation: 8,
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: secondaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      
      // Divider Theme
      dividerTheme: const DividerThemeData(
        thickness: 1,
        space: 1,
        color: Colors.grey,
      ),
    );
  }
  
  /// Dark theme configuration
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: darkPrimaryColor,
        secondary: secondaryColor,
        error: errorColor,
        surface: darkSurfaceColor,
      ),
      
      // App Bar Theme
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: darkSurfaceColor,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      
      // Card Theme
      cardTheme: const CardThemeData(
        elevation: 4,
        color: darkSurfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppConstants.borderRadius)),
        ),
        margin: EdgeInsets.symmetric(
          horizontal: AppConstants.defaultPadding,
          vertical: AppConstants.smallPadding,
        ),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          backgroundColor: darkPrimaryColor,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.largePadding,
            vertical: AppConstants.defaultPadding,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[800],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: const BorderSide(color: darkPrimaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        contentPadding: const EdgeInsets.all(AppConstants.defaultPadding),
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: darkSurfaceColor,
        selectedItemColor: darkPrimaryColor,
        unselectedItemColor: Colors.grey,
        elevation: 8,
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: secondaryColor,
        foregroundColor: Colors.black,
        elevation: 4,
      ),
    );
  }
  
  /// Get message bubble color based on theme and sender
  static Color getMessageBubbleColor(BuildContext context, bool isSent) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (isSent) {
      return isDark ? darkSentMessageColor : sentMessageColor;
    } else {
      return isDark ? darkReceivedMessageColor : receivedMessageColor;
    }
  }
  
  /// Get text color for message bubbles
  static Color getMessageTextColor(BuildContext context, bool isSent) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (isSent) {
      return Colors.white;
    } else {
      return isDark ? Colors.white : Colors.black87;
    }
  }
  
  /// Get connection status color
  static Color getConnectionStatusColor(bool isOnline, bool isConnecting) {
    if (isConnecting) return connectingColor;
    return isOnline ? onlineColor : offlineColor;
  }
}