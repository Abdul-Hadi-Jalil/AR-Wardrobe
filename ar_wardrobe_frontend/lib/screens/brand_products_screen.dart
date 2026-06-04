import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/brand_catalog.dart';
import '../models/clothing_item.dart';
import '../models/cart_item.dart';
import '../models/saved_outfit.dart';
import '../services/firestore_service.dart';
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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: FutureBuilder<BrandInfo?>(
          future: _brandFuture,
          builder: (context, snapshot) {
            final name =
                snapshot.data?.displayName ??
                BrandCatalog.displayNameFor(widget.brandId);
            return Text(
              name,
              style: TextStyle(
                color: Colors.black,
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<BrandInfo?>(
        future: _brandFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2ACAEA)),
            );
          }

          final brand = snapshot.data;
          if (brand == null || brand.products.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(24.w),
                child: Text(
                  'No clothes found for this brand.\nAdd images to assets/brand_clothes/${widget.brandId}/',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 16.sp),
                ),
              ),
            );
          }

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: GridView.builder(
              padding: EdgeInsets.only(top: 16.h, bottom: 100.h),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12.w,
                mainAxisSpacing: 12.h,
                childAspectRatio: 0.65,
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
        SnackBar(
          content: Text('Please login to add items to cart'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final firestoreService = FirestoreService();
    try {
      final cartItem = CartItem(
        id: '${const Uuid().v4()}',
        productId: product.id,
        name: product.name,
        assetPath: product.assetPath,
        brandId: product.brandId,
        quantity: 1,
        addedAt: DateTime.now(),
        price: product.price != null && product.price! > 0
            ? product.price!
            : (20 + Random().nextDouble() * 80),
      );
      await firestoreService.addToCart(cartItem);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.name} added to cart'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding to cart: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _saveOutfit(BuildContext context, ClothingItem product) async {
    print('DEBUG: Save outfit button pressed for product: ${product.name}');
    final user = FirebaseAuth.instance.currentUser;
    print('DEBUG: Current user: ${user?.email ?? "null"}');
    if (user == null) {
      print('DEBUG: User not authenticated, showing login prompt');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please login to save outfits'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final firestoreService = FirestoreService();
    try {
      print('DEBUG: Creating outfit object');
      final outfit = SavedOutfit(
        id: '${const Uuid().v4()}',
        outfitName: product.name,
        productIds: [product.id],
        productAssets: [product.assetPath],
        savedAt: DateTime.now(),
      );
      print('DEBUG: Attempting to save outfit to Firestore');
      await firestoreService.addToSavedOutfits(outfit);
      print('DEBUG: Outfit saved successfully');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.name} saved as outfit'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('DEBUG: Error saving outfit: $e');
      print('DEBUG: Error type: ${e.runtimeType}');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving outfit: $e'),
            backgroundColor: Colors.red,
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
    // Generate random price if price is 0 or null
    final random = Random();
    return 20 + random.nextDouble() * 80;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTryOn,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(12.r),
                  ),
                  color: Colors.grey[100],
                ),
                padding: EdgeInsets.all(8.r),
                child: Image.asset(product.assetPath, fit: BoxFit.contain),
              ),
            ),
            Expanded(
              flex: 5,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '\$${_displayPrice.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: const Color(0xFF2ACAEA),
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    SizedBox(
                      width: double.infinity,
                      height: 24.h,
                      child: ElevatedButton(
                        onPressed: onTryOn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2ACAEA),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: Text(
                          'Try On',
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 22.h,
                            child: ElevatedButton(
                              onPressed: onAddToCart,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF2ACAEA),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6.r),
                                  side: const BorderSide(
                                    color: Color(0xFF2ACAEA),
                                  ),
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              child: Text(
                                'Add to Cart',
                                style: TextStyle(
                                  fontSize: 8.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: SizedBox(
                            height: 22.h,
                            child: ElevatedButton(
                              onPressed: onSaveOutfit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF2ACAEA),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6.r),
                                  side: const BorderSide(
                                    color: Color(0xFF2ACAEA),
                                  ),
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              child: Text(
                                'Saved Outfits',
                                style: TextStyle(
                                  fontSize: 8.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
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
      ),
    );
  }
}
