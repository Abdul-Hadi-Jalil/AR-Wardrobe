import 'package:flutter/services.dart';

import 'clothing_item.dart';
import 'product_prices.dart';

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
    'alkaram': ['assets/brand_clothes/alkaram/shirt.png'],
    'bonanza': ['assets/brand_clothes/bonanza/off_white_shirt.png'],
    'chinyere': ['assets/brand_clothes/chinyere/light_peach_shirt.png'],
    'ideas': ['assets/brand_clothes/ideas/grey_hat.png'],
    'levis': ['assets/brand_clothes/levis/beig_pant.png'],
    'lime_light': [
      'assets/brand_clothes/lime_light/shirt_j.jpg',
      'assets/brand_clothes/lime_light/neon_limelight.jpg',
      'assets/brand_clothes/lime_light/blue_pant.png',
      'assets/brand_clothes/lime_light/white_pant.png',
    ],
    'nike': ['assets/brand_clothes/nike/grey_pant.png'],
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
    final productsByBrand = await _groupProductsByBrand(manifest);

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

  static Future<Map<String, List<ClothingItem>>> _groupProductsByBrand(
    AssetManifest manifest,
  ) async {
    final manifestPaths = manifest
        .listAssets()
        .where((path) => path.startsWith(_clothesRoot))
        .where(_isImageAsset)
        .toSet();

    final grouped = <String, List<ClothingItem>>{};

    void addProduct(String brandId, String path) {
      final items = grouped.putIfAbsent(brandId, () => []);
      if (items.any((item) => item.assetPath == path)) return;
      final price = ProductPrices.getPrice(path);
      items.add(
        ClothingItem(
          id: path,
          name: nameFromFile(path.split('/').last),
          assetPath: path,
          brandId: brandId,
          category: ClothingItem.categoryFromAssetPath(path),
          price: price,
        ),
      );
    }

    for (final path in manifestPaths) {
      final brandId = _brandIdFromClothesPath(path);
      if (brandId == null) continue;
      addProduct(brandId, path);
    }

    // Fallback assets are only added when the file is actually bundled.
    // This prevents phantom products that would render an "asset not found"
    // error when the underlying image has been removed from the folder.
    for (final entry in _knownBrandAssets.entries) {
      for (final path in entry.value) {
        if (manifestPaths.contains(path)) continue;
        if (await _assetExists(path)) {
          addProduct(entry.key, path);
        }
      }
    }

    return grouped;
  }

  /// Returns true when [path] can be loaded from the asset bundle.
  static Future<bool> _assetExists(String path) async {
    try {
      await rootBundle.load(path);
      return true;
    } catch (_) {
      return false;
    }
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
