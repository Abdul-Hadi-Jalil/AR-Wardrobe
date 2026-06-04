class CartItem {
  final String id;
  final String productId;
  final String name;
  final String assetPath;
  final String brandId;
  final int quantity;
  final DateTime addedAt;
  final double price;

  CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.assetPath,
    required this.brandId,
    this.quantity = 1,
    required this.addedAt,
    this.price = 0.0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'productId': productId,
        'name': name,
        'assetPath': assetPath,
        'brandId': brandId,
        'quantity': quantity,
        'addedAt': addedAt.toIso8601String(),
        'price': price,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        id: json['id'] as String,
        productId: json['productId'] as String,
        name: json['name'] as String,
        assetPath: json['assetPath'] as String,
        brandId: json['brandId'] as String,
        quantity: json['quantity'] as int? ?? 1,
        addedAt: DateTime.parse(json['addedAt'] as String),
        price: json['price'] != null ? (json['price'] as num).toDouble() : 0.0,
      );

  CartItem copyWith({
    String? id,
    String? productId,
    String? name,
    String? assetPath,
    String? brandId,
    int? quantity,
    DateTime? addedAt,
    double? price,
  }) =>
      CartItem(
        id: id ?? this.id,
        productId: productId ?? this.productId,
        name: name ?? this.name,
        assetPath: assetPath ?? this.assetPath,
        brandId: brandId ?? this.brandId,
        quantity: quantity ?? this.quantity,
        addedAt: addedAt ?? this.addedAt,
        price: price ?? this.price,
      );
}
