import 'package:flutter/material.dart';

class Product {
  final String title;
  final int price;
  final String subtitle;
  final Color color;
  int quantity;

  Product({
    required this.title,
    required this.price,
    required this.subtitle,
    this.color = Colors.grey,
    this.quantity = 0,
  });
} 