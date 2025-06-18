// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // Màu sắc chủ đạo (bạn có thể định nghĩa màu sắc riêng)
  static const Color _primaryColor = Colors.teal; // Ví dụ: Màu xanh teal
  static const Color _accentColor = Colors.amber;  // Ví dụ: Màu vàng hổ phách

  // --- Light Theme ---
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: _primaryColor,
    // colorScheme: ColorScheme.light( // Cách mới hơn để định nghĩa màu
    //   primary: _primaryColor,
    //   secondary: _accentColor,
    //   surface: Colors.white,
    //   background: Colors.grey.shade100,
    //   error: Colors.red,
    //   onPrimary: Colors.white,
    //   onSecondary: Colors.black,
    //   onSurface: Colors.black,
    //   onBackground: Colors.black,
    //   onError: Colors.white,
    // ),
    scaffoldBackgroundColor: Colors.grey.shade100, // Màu nền cho Scaffold
    appBarTheme: AppBarTheme(
      elevation: 1.0,
      centerTitle: true,
      backgroundColor: _primaryColor, // Màu nền AppBar
      foregroundColor: Colors.white, // Màu chữ và icon trên AppBar
      iconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 20.0,
        fontWeight: FontWeight.bold,
      ),
    ),
    textTheme: const TextTheme( // Tùy chỉnh font chữ
      displayLarge: TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold, color: Colors.black87),
      displayMedium: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: Colors.black87),
      headlineSmall: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Colors.black87),
      titleLarge: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.black87),
      titleMedium: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600, color: Colors.black87),
      titleSmall: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w500, color: Colors.black54),
      bodyLarge: TextStyle(fontSize: 16.0, color: Colors.black87),
      bodyMedium: TextStyle(fontSize: 14.0, color: Colors.black87),
      bodySmall: TextStyle(fontSize: 12.0, color: Colors.black54),
      labelLarge: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.white), // Cho nút ElevatedButton
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        textStyle: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _primaryColor,
        textStyle: const TextStyle(fontSize: 15.0, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: _primaryColor, width: 2.0),
      ),
      labelStyle: TextStyle(color: Colors.grey.shade700),
      hintStyle: TextStyle(color: Colors.grey.shade500),
    ),
    cardTheme: CardTheme(
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      selectedItemColor: _primaryColor,
      unselectedItemColor: Colors.grey.shade600,
      backgroundColor: Colors.white,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
    ),
    // Bạn có thể thêm các tùy chỉnh khác ở đây
    // floatingActionButtonTheme: FloatingActionButtonThemeData(
    //   backgroundColor: _accentColor,
    //   foregroundColor: Colors.black,
    // ),
  );

  // --- Dark Theme (Tùy chọn) ---
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: _primaryColor, // Có thể chọn màu khác cho dark mode
    // colorScheme: ColorScheme.dark(
    //   primary: _primaryColor, // Hoặc một màu tối hơn của _primaryColor
    //   secondary: _accentColor,
    //   surface: Colors.grey.shade800,
    //   background: Colors.grey.shade900,
    //   error: Colors.redAccent,
    //   onPrimary: Colors.white,
    //   onSecondary: Colors.white,
    //   onSurface: Colors.white,
    //   onBackground: Colors.white,
    //   onError: Colors.black,
    // ),
    scaffoldBackgroundColor: Colors.grey.shade900,
    appBarTheme: AppBarTheme(
      elevation: 1.0,
      centerTitle: true,
      backgroundColor: Colors.grey.shade800, // Màu nền AppBar cho dark mode
      foregroundColor: Colors.white,
      iconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 20.0,
        fontWeight: FontWeight.bold,
      ),
    ),
    textTheme: const TextTheme( // Tùy chỉnh font chữ cho dark mode
      displayLarge: TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold, color: Colors.white70),
      displayMedium: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: Colors.white70),
      headlineSmall: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Colors.white70),
      titleLarge: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.white70),
      titleMedium: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600, color: Colors.white70),
      titleSmall: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w500, color: Colors.white60),
      bodyLarge: TextStyle(fontSize: 16.0, color: Colors.white70),
      bodyMedium: TextStyle(fontSize: 14.0, color: Colors.white70),
      bodySmall: TextStyle(fontSize: 12.0, color: Colors.white60),
      labelLarge: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.white),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor, // Giữ màu primary hoặc thay đổi
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        textStyle: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.grey.shade700),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: _primaryColor, width: 2.0),
      ),
      labelStyle: TextStyle(color: Colors.grey.shade400),
      hintStyle: TextStyle(color: Colors.grey.shade600),
    ),
    cardTheme: CardTheme(
      elevation: 2.0,
      color: Colors.grey.shade800,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      selectedItemColor: _primaryColor,
      unselectedItemColor: Colors.grey.shade500,
      backgroundColor: Colors.grey.shade800,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
    ),
    // ... các tùy chỉnh khác cho dark theme
  );
}