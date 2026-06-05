class UserOrder {
  final String id;
  final List<OrderItem> items;
  final double totalPrice;
  final int totalItems;
  final DateTime orderDate;
  final String status;

  UserOrder({
    required this.id,
    required this.items,
    required this.totalPrice,
    required this.totalItems,
    required this.orderDate,
    this.status = 'Pending',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'items': items.map((item) => item.toJson()).toList(),
        'totalPrice': totalPrice,
        'totalItems': totalItems,
        'orderDate': orderDate.toIso8601String(),
        'status': status,
      };

  factory UserOrder.fromJson(Map<String, dynamic> json) => UserOrder(
        id: json['id'] as String,
        items: (json['items'] as List)
            .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
            .toList(),
        totalPrice: (json['totalPrice'] as num).toDouble(),
        totalItems: json['totalItems'] as int,
        orderDate: DateTime.parse(json['orderDate'] as String),
        status: json['status'] as String? ?? 'Pending',
      );
}

class OrderItem {
  final String productId;
  final String name;
  final String assetPath;
  final String brandId;
  final int quantity;
  final double price;

  OrderItem({
    required this.productId,
    required this.name,
    required this.assetPath,
    required this.brandId,
    required this.quantity,
    required this.price,
  });

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'name': name,
        'assetPath': assetPath,
        'brandId': brandId,
        'quantity': quantity,
        'price': price,
      };

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        productId: json['productId'] as String,
        name: json['name'] as String,
        assetPath: json['assetPath'] as String,
        brandId: json['brandId'] as String,
        quantity: json['quantity'] as int,
        price: (json['price'] as num).toDouble(),
      );
}
