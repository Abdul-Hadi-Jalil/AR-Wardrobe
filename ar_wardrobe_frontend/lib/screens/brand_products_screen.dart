import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/brand_catalog.dart';
import '../models/clothing_item.dart';
import '../models/cart_item.dart';
import '../models/product_prices.dart';
import '../models/saved_outfit.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_widgets.dart';
import 'camera_screen.dart';

class BrandProductsScreen extends StatefulWidget {
  const BrandProductsScreen({super.key, required this.brandId});

  final String brandId;

  @override
  State<BrandProductsScreen> createState() => _BrandProductsScreenState();
}

class _BrandProductsScreenState extends State<BrandProductsScreen> {
  late Future<BrandInfo?> _brandFuture;

  @override
  void initState() {
    super.initState();
    _brandFuture = BrandCatalog.loadBrand(widget.brandId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: FutureBuilder<BrandInfo?>(
          future: _brandFuture,
          builder: (context, snapshot) {
            final name = snapshot.data?.displayName ??
                BrandCatalog.displayNameFor(widget.brandId);
            return Text(name);
          },
        ),
      ),
      body: FutureBuilder<BrandInfo?>(
        future: _brandFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final brand = snapshot.data;
          if (brand == null || brand.products.isEmpty) {
            return EmptyState(
              icon: Icons.checkroom_outlined,
              title: 'No clothes found',
              subtitle:
                  'Add images to assets/brand_clothes/${widget.brandId}/',
            );
          }

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: GridView.builder(
              padding: EdgeInsets.only(top: 12.h, bottom: 110.h),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14.w,
                mainAxisSpacing: 14.h,
                childAspectRatio: 0.58,
              ),
              itemCount: brand.products.length,
              itemBuilder: (context, index) {
                final product = brand.products[index];
                return _ProductCard(
                  product: product,
                  onTryOn: () => openTryOnCamera(context, product),
                  onAddToCart: () => _addToCart(context, product),
                  onSaveOutfit: () => _saveOutfit(context, product),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _addToCart(BuildContext context, ClothingItem product) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to add items to cart'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final firestoreService = FirestoreService();
    try {
      final cartItems = await firestoreService.getCartItems().first;

      if (cartItems.any((item) => item.productId == product.id)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${product.name} is already in your cart'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
        return;
      }

      final cartItem = CartItem(
        id: const Uuid().v4(),
        productId: product.id,
        name: product.name,
        assetPath: product.assetPath,
        brandId: product.brandId,
        quantity: 1,
        addedAt: DateTime.now(),
        price: product.price != null && product.price! > 0
            ? product.price!
            : ProductPrices.getPrice(product.id),
      );
      await firestoreService.addToCart(cartItem);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.name} added to cart'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding to cart: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _saveOutfit(BuildContext context, ClothingItem product) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to save outfits'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final firestoreService = FirestoreService();
    try {
      final outfit = SavedOutfit(
        id: const Uuid().v4(),
        outfitName: product.name,
        productIds: [product.id],
        productAssets: [product.assetPath],
        savedAt: DateTime.now(),
      );
      await firestoreService.addToSavedOutfits(outfit);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.name} saved as outfit'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving outfit: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.onTryOn,
    required this.onAddToCart,
    required this.onSaveOutfit,
  });

  final ClothingItem product;
  final VoidCallback onTryOn;
  final VoidCallback onAddToCart;
  final VoidCallback onSaveOutfit;

  double get _displayPrice {
    if (product.price != null && product.price! > 0) {
      return product.price!;
    }
    return ProductPrices.getPrice(product.id);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(AppRadius.lg),
                    ),
                  ),
                  padding: EdgeInsets.all(10.r),
                  child: SafeAssetImage(assetPath: product.assetPath),
                ),
                Positioned(
                  top: 8.h,
                  right: 8.w,
                  child: _CircleIconButton(
                    icon: Icons.bookmark_border_rounded,
                    onTap: onSaveOutfit,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '\$${_displayPrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: onTryOn,
                          child: Container(
                            height: 36.h,
                            decoration: BoxDecoration(
                              gradient: AppGradients.brandHorizontal,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt_rounded,
                                    color: Colors.white, size: 15.sp),
                                SizedBox(width: 5.w),
                                Text(
                                  'Try On',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      GestureDetector(
                        onTap: onAddToCart,
                        child: Container(
                          width: 36.h,
                          height: 36.h,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Icon(Icons.add_shopping_cart_rounded,
                              color: AppColors.primary, size: 17.sp),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32.w,
        height: 32.w,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: AppShadows.soft,
        ),
        child: Icon(icon, size: 18.sp, color: AppColors.primary),
      ),
    );
  }
}
