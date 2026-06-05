import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';

class ProductPrices {
  static Map<String, double> _prices = {};
  static bool _loaded = false;

  static Future<void> loadPrices() async {
    if (_loaded) return;

    try {
      final jsonString = await rootBundle.loadString('assets/product_prices.json');
      final Map<String, dynamic> data = json.decode(jsonString);
      _prices = data.map<String, double>((key, value) => MapEntry(key, (value as num).toDouble()));
      _loaded = true;
    } catch (e) {
      // If file doesn't exist, initialize empty map
      _prices = {};
      _loaded = true;
    }
  }

  static double getPrice(String productId) {
    if (!_loaded) {
      // Fallback: generate consistent price based on product ID hash
      return _generateConsistentPrice(productId);
    }

    return _prices[productId] ?? _generateConsistentPrice(productId);
  }

  static double _generateConsistentPrice(String productId) {
    // Generate a consistent price based on product ID hash
    final hash = productId.hashCode.abs();
    final random = Random(hash);
    return 20 + random.nextDouble() * 80;
  }

  static Future<void> savePrice(String productId, double price) async {
    _prices[productId] = price;
    _loaded = true;
    // Note: In a real app, you'd save this to a file or database
  }
}
