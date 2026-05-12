import 'package:flutter/material.dart';

class AppConstants {
  static const List<String> categories = [
    'Food',
    'Transport',
    'Health',
    'Shopping',
    'Entertainment',
    'Bills',
    'Other',
  ];

  // Upgraded icon set — rounded variants look more polished
  static const Map<String, IconData> categoryIcons = {
    'Food': Icons.restaurant_rounded,
    'Transport': Icons.directions_car_rounded,
    'Health': Icons.favorite_rounded,
    'Shopping': Icons.shopping_bag_rounded,
    'Entertainment': Icons.movie_rounded,
    'Bills': Icons.receipt_long_rounded,
    'Other': Icons.tag_rounded,
  };

  // Curated, harmonious palette — no plain Material swatch colors
  static const Map<String, Color> categoryColors = {
    'Food': Color(0xFFFF8C42),        // warm amber-orange
    'Transport': Color(0xFF5B8DEF),   // cornflower blue
    'Health': Color(0xFFEF5DA8),      // rose pink
    'Shopping': Color(0xFF9B72CF),    // soft violet
    'Entertainment': Color(0xFFFF6B9D), // hot pink
    'Bills': Color(0xFF00BFA5),       // teal (matches brand accent)
    'Other': Color(0xFF8A9BB0),       // slate blue-gray
  };
}
