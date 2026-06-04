class SavedOutfit {
  final String id;
  final String outfitName;
  final List<String> productIds;
  final List<String> productAssets;
  final DateTime savedAt;

  SavedOutfit({
    required this.id,
    required this.outfitName,
    required this.productIds,
    required this.productAssets,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'outfitName': outfitName,
    'productIds': productIds,
    'productAssets': productAssets,
    'savedAt': savedAt.toIso8601String(),
  };

  factory SavedOutfit.fromJson(Map<String, dynamic> json) => SavedOutfit(
    id: json['id'] as String,
    outfitName: json['outfitName'] as String,
    productIds: List<String>.from(json['productIds'] as List),
    productAssets: List<String>.from(json['productAssets'] as List),
    savedAt: DateTime.parse(json['savedAt'] as String),
  );
}
