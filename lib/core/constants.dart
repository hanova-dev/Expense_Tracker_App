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

  static const Map<String, IconData> categoryIcons = {
    'Food': Icons.restaurant,
    'Transport': Icons.directions_car,
    'Health': Icons.local_hospital,
    'Shopping': Icons.shopping_cart,
    'Entertainment': Icons.movie,
    'Bills': Icons.receipt,
    'Other': Icons.more_horiz,
  };

  static const Map<String, Color> categoryColors = {
    'Food': Colors.orange,
    'Transport': Colors.blue,
    'Health': Colors.red,
    'Shopping': Colors.purple,
    'Entertainment': Colors.pink,
    'Bills': Colors.teal,
    'Other': Colors.grey,
  };
}
