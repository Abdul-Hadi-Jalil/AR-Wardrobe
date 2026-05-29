enum ClothingCategory { shirts }

class ClothingItem {
  const ClothingItem({
    required this.id,
    required this.name,
    required this.assetPath,
    required this.category,
  });

  final String id;
  final String name;
  final String assetPath;
  final ClothingCategory category;

  static const String jClothesShirtPath = 'assets/j.clothes/shirts/shirt_j.jpg';

  static const ClothingItem shirt = ClothingItem(
    id: 'shirt_j',
    name: 'J.Clothes Shirt',
    assetPath: jClothesShirtPath,
    category: ClothingCategory.shirts,
  );

  static const List<ClothingItem> catalog = [shirt];

  static List<ClothingItem> forCategory(ClothingCategory category) {
    return catalog.where((item) => item.category == category).toList();
  }
}
