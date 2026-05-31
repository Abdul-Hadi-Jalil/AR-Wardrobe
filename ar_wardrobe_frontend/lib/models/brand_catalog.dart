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
  final String? logoAsset;
  final List<ClothingItem> products;
}

class BrandCatalog {
  BrandCatalog._();

  static const _clothesRoot = 'assets/brand_clothes/';

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

  static const _logos = <String, String>{
    'lime_light': 'assets/brand_logos/lime_light.png',
    'outfitters': 'assets/brand_logos/outfitters.png',
    'chinyere': 'assets/brand_logos/chinyere.png',
    'ideas': 'assets/brand_logos/ideas.jpg',
    'bonanza': 'assets/brand_logos/bonanza.jpg',
    'alkaram': 'assets/brand_logos/alkaram.jpg',
    'nike': 'assets/brand_logos/nike.png',
    'levis': 'assets/brand_logos/levis.jpg',
  };

  static Future<List<BrandInfo>> loadBrands() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final assets = manifest
        .listAssets()
        .where((path) => path.startsWith(_clothesRoot))
        .where(_isImageAsset)
        .toList()
      ..sort();

    final grouped = <String, List<String>>{};
    for (final path in assets) {
      final relative = path.substring(_clothesRoot.length);
      final slash = relative.indexOf('/');
      if (slash <= 0) continue;
      final brandId = relative.substring(0, slash);
      grouped.putIfAbsent(brandId, () => []).add(path);
    }

    return grouped.entries.map((entry) {
      final brandId = entry.key;
      final products = entry.value.map((path) {
        final fileName = path.split('/').last;
        return ClothingItem(
          id: path,
          name: nameFromFile(fileName),
          assetPath: path,
          brandId: brandId,
        );
      }).toList();

      return BrandInfo(
        id: brandId,
        displayName: displayNameFor(brandId),
        logoAsset: _logos[brandId],
        products: products,
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

  static String displayNameFor(String brandId) {
    return _displayNames[brandId] ??
        brandId
            .split('_')
            .map((part) => part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}')
            .join(' ');
  }

  static String nameFromFile(String fileName) {
    final base = fileName.split('.').first;
    return base
        .split('_')
        .map((part) => part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}')
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
