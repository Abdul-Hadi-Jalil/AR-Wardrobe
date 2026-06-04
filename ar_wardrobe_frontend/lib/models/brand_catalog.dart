import 'dart:math';

import 'package:flutter/services.dart';

import 'clothing_item.dart';

class BrandInfo {
  const BrandInfo({
    required this.id,
    required this.displayName,
    required this.logoAsset,
    required this.products,
  });

  final String id;
  final String displayName;
  final String logoAsset;
  final List<ClothingItem> products;
}

class BrandCatalog {
  BrandCatalog._();

  static const _logosRoot = 'assets/brand_logos/';
  static const _clothesRoot = 'assets/brand_clothes/';

  /// Fallback paths for each brand folder. Ensures products load even when the
  /// asset manifest omits nested or webp files. Add entries when new brands
  /// are added under assets/brand_clothes/.
  static const _knownBrandAssets = <String, List<String>>{
    'lime_light': [
      'assets/brand_clothes/lime_light/shirt_j.jpg',
      'assets/brand_clothes/lime_light/neon_limelight.jpg',
    ],
    'outfitters': [
      'assets/brand_clothes/outfitters/peach_shirt.webp',
      'assets/brand_clothes/outfitters/shield_sunglasses.webp',
    ],
  };

  static const _displayNames = <String, String>{
    'lime_light': 'LIMELIGHT',
    'outfitters': 'Outfitters',
    'chinyere': 'CHINYERE',
    'ideas': 'Ideas by Gul Ahmed',
    'bonanza': 'BONANZA SATRANGI',
    'alkaram': 'alkaramstudio',
    'nike': 'NIKE',
    'levis': "Levi's",
  };

  static Future<List<BrandInfo>> loadBrands() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final productsByBrand = _groupProductsByBrand(manifest);

    final logoAssets = manifest
        .listAssets()
        .where((path) => path.startsWith(_logosRoot))
        .where(_isImageAsset)
        .toList()
      ..sort();

    return logoAssets.map((logoPath) {
      final brandId = _brandIdFromLogoPath(logoPath);
      return BrandInfo(
        id: brandId,
        displayName: displayNameFor(brandId),
        logoAsset: logoPath,
        products: productsByBrand[brandId] ?? const [],
      );
    }).toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
  }

  static Future<BrandInfo?> loadBrand(String brandId) async {
    final brands = await loadBrands();
    for (final brand in brands) {
      if (brand.id == brandId) return brand;
    }
    return null;
  }

  static Map<String, List<ClothingItem>> _groupProductsByBrand(
    AssetManifest manifest,
  ) {
    final manifestPaths = manifest
        .listAssets()
        .where((path) => path.startsWith(_clothesRoot))
        .where(_isImageAsset)
        .toSet();

    final grouped = <String, List<ClothingItem>>{};

    void addProduct(String brandId, String path) {
      final items = grouped.putIfAbsent(brandId, () => []);
      if (items.any((item) => item.assetPath == path)) return;
      final random = Random();
      final price = 20 + random.nextDouble() * 80; // Random price between 20 and 100
      items.add(
        ClothingItem(
          id: path,
          name: nameFromFile(path.split('/').last),
          assetPath: path,
          brandId: brandId,
          category: ClothingItem.categoryFromAssetPath(path),
          price: double.parse(price.toStringAsFixed(2)),
        ),
      );
    }

    for (final path in manifestPaths) {
      final brandId = _brandIdFromClothesPath(path);
      if (brandId == null) continue;
      addProduct(brandId, path);
    }

    for (final entry in _knownBrandAssets.entries) {
      for (final path in entry.value) {
        addProduct(entry.key, path);
      }
    }

    return grouped;
  }

  static String? _brandIdFromClothesPath(String path) {
    if (!path.startsWith(_clothesRoot)) return null;
    final relative = path.substring(_clothesRoot.length);
    final slash = relative.indexOf('/');
    if (slash <= 0) return null;
    return relative.substring(0, slash);
  }

  static String _brandIdFromLogoPath(String logoPath) {
    final fileName = logoPath.split('/').last;
    return fileName.split('.').first;
  }

  static String displayNameFor(String brandId) {
    return _displayNames[brandId] ??
        brandId
            .split('_')
            .map(
              (part) => part.isEmpty
                  ? part
                  : '${part[0].toUpperCase()}${part.substring(1)}',
            )
            .join(' ');
  }

  static String nameFromFile(String fileName) {
    final base = fileName.split('.').first;
    return base
        .split('_')
        .map(
          (part) => part.isEmpty
              ? part
              : '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }

  static bool _isImageAsset(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp');
  }
}
