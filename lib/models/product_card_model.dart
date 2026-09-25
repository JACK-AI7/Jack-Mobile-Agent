// lib/models/product_card_model.dart
import 'package:flutter/material.dart';

class ProductCardItem {
  final String title;
  final String price;
  final String ratingValue;
  final String reviewsCount;
  final String screenText;
  final Color screenGlowColor;
  final List<Color> wallpaperColors;
  final Map<String, String> specs;
  final String? purchaseUrl;

  const ProductCardItem({
    required this.title,
    required this.price,
    required this.ratingValue,
    required this.reviewsCount,
    required this.screenText,
    required this.screenGlowColor,
    required this.wallpaperColors,
    required this.specs,
    this.purchaseUrl,
  });
}
