import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:uuid/uuid.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_widgets.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 8.h),
              child: Row(
                children: [
                  Text(
                    'My Cart',
                    style: TextStyle(
                      fontSize: 26.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<CartItem>>(
                stream: _firestoreService.getCartItems(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary),
                    );
                  }

                  if (snapshot.hasError) {
                    return const EmptyState(
                      icon: Icons.error_outline_rounded,
                      title: 'Error loading cart',
                    );
                  }

                  final cartItems = snapshot.data ?? [];
                  if (cartItems.isEmpty) {
                    return const EmptyState(
                      icon: Icons.shopping_bag_outlined,
                      title: 'Your cart is empty',
                      subtitle: 'Add items to get started.',
                    );
                  }

                  int totalItems =
                      cartItems.fold(0, (sum, item) => sum + (item.quantity));
                  double totalPrice = cartItems.fold(
                      0, (sum, item) => sum + (item.price * item.quantity));

                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 16.h),
                          itemCount: cartItems.length,
                          itemBuilder: (context, index) {
                            final item = cartItems[index];
                            return _CartItemCard(
                              item: item,
                              onQuantityChanged: (newQuantity) async {
                                if (newQuantity <= 0) {
                                  await _firestoreService
                                      .removeFromCart(item.id);
                                } else {
                                  await _firestoreService
                                      .updateCartItemQuantity(
                                          item.id, newQuantity);
                                }
                              },
                              onDelete: () async {
                                await _firestoreService.removeFromCart(item.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          '${item.name} removed from cart'),
                                    ),
                                  );
                                }
                              },
                            );
                          },
                        ),
                      ),
                      _CheckoutBar(
                        totalItems: totalItems,
                        totalPrice: totalPrice,
                        onCheckout: () =>
                            _placeOrder(cartItems, totalItems, totalPrice),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _placeOrder(
    List<CartItem> cartItems,
    int totalItems,
    double totalPrice,
  ) async {
    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty')),
      );
      return;
    }

    try {
      final orderItems = cartItems
          .map((item) => OrderItem(
                productId: item.productId,
                name: item.name,
                assetPath: item.assetPath,
                brandId: item.brandId,
                quantity: item.quantity,
                price: item.price,
              ))
          .toList();

      final order = UserOrder(
        id: const Uuid().v4(),
        items: orderItems,
        totalPrice: totalPrice,
        totalItems: totalItems,
        orderDate: DateTime.now(),
        status: 'Pending',
      );

      await _firestoreService.addOrder(order);
      await _firestoreService.clearCart();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order placed successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error placing order: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }
}

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({
    required this.totalItems,
    required this.totalPrice,
    required this.onCheckout,
  });

  final int totalItems;
  final double totalPrice;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 28.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total ($totalItems items)',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '\$${totalPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          GradientButton(
            label: 'Place Order',
            icon: Icons.check_circle_outline_rounded,
            onPressed: onCheckout,
          ),
        ],
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final CartItem item;
  final Function(int) onQuantityChanged;
  final VoidCallback onDelete;

  const _CartItemCard({
    required this.item,
    required this.onQuantityChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          Container(
            width: 84.w,
            height: 84.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              color: AppColors.surfaceAlt,
            ),
            padding: EdgeInsets.all(6.w),
            child: SafeAssetImage(assetPath: item.assetPath),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: onDelete,
                      child: Icon(Icons.close_rounded,
                          size: 18.sp, color: AppColors.textMuted),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                Text(
                  item.brandId.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${item.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Row(
                        children: [
                          _QtyButton(
                            icon: Icons.remove_rounded,
                            onTap: () => onQuantityChanged(item.quantity - 1),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10.w),
                            child: Text(
                              '${item.quantity}',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          _QtyButton(
                            icon: Icons.add_rounded,
                            onTap: () => onQuantityChanged(item.quantity + 1),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: EdgeInsets.all(7.w),
        child: Icon(icon, size: 16.sp, color: AppColors.primary),
      ),
    );
  }
}
