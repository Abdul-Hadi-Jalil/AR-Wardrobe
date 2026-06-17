enum ClothingCategory { glasses, hats, shirts, pants }

class ClothingItem {
  const ClothingItem({
    required this.id,
    required this.name,
    required this.assetPath,
    required this.brandId,
    required this.category,
    this.price,
  });

  final String id;
  final String name;
  final String assetPath;
  final String brandId;
  final ClothingCategory category;
  final double? price;

  static ClothingCategory categoryFromAssetPath(String path) {
    final lower = path.toLowerCase();
    if (lower.contains('glass') ||
        lower.contains('sunglass') ||
        lower.contains('goggle') ||
        lower.contains('spectacle') ||
        lower.contains('eyewear')) {
      return ClothingCategory.glasses;
    }
    if (lower.contains('hat') ||
        lower.contains('cap') ||
        lower.contains('beanie') ||
        lower.contains('headwear')) {
      return ClothingCategory.hats;
    }
    if (lower.contains('pant') ||
        lower.contains('trouser') ||
        lower.contains('jean') ||
        lower.contains('chino')) {
      return ClothingCategory.pants;
    }
    return ClothingCategory.shirts;
  }

  bool get usesFace =>
      category == ClothingCategory.glasses || category == ClothingCategory.hats;

  bool get usesPose =>
      category == ClothingCategory.shirts || category == ClothingCategory.pants;
}
