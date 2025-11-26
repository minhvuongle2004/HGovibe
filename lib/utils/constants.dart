import 'package:flutter/material.dart';

class AppConstants {
  // App Info
  static const String appName = 'Smart Travel App';
  static const String appVersion = '1.0.0';
  
  // Categories
  static const List<String> categories = [
    'Tất cả',
    'Thiên nhiên',
    'Văn hóa',
    'Ẩm thực',
    'Mua sắm',
    'Giải trí',
  ];
  
  static const Map<String, IconData> categoryIcons = {
    'Tất cả': Icons.explore,
    'Thiên nhiên': Icons.nature,
    'Văn hóa': Icons.museum,
    'Ẩm thực': Icons.restaurant,
    'Mua sắm': Icons.shopping_bag,
    'Giải trí': Icons.celebration,
  };
  
  // Colors
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color secondaryColor = Color(0xFF03DAC6);
  static const Color errorColor = Color(0xFFB00020);
  
  // Firestore Collections
  static const String destinationsCollection = 'destinations';
  static const String tripsCollection = 'trips';
  static const String favoritesCollection = 'user_favorites';
  static const String usersCollection = 'users';
}