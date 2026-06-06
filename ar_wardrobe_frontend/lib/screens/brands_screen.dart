import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/brand_catalog.dart';
import '../theme/app_theme.dart';
import '../theme/app_widgets.dart';
import 'brand_products_screen.dart';

class BrandsScreen extends StatefulWidget {
  const BrandsScreen({super.key});

  @override
  State<BrandsScreen> createState() => _BrandsScreenState();
}

class _BrandsScreenState extends State<BrandsScreen> {
  late Future<List<BrandInfo>> _brandsFuture;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _brandsFuture = BrandCatalog.loadBrands();
  }

  List<BrandInfo> _filterBrands(List<BrandInfo> brands) {
    if (_searchQuery.isEmpty) return brands;
    final query = _searchQuery.toLowerCase();
    return brands
        .where((brand) => brand.displayName.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 12.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Discover',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'Top Brands',
                        style: TextStyle(
                          fontSize: 26.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 46.w,
                    height: 46.w,
                    decoration: BoxDecoration(
                      gradient: AppGradients.brand,
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Icon(Icons.checkroom_rounded,
                        color: Colors.white, size: 24.sp),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              AppSearchField(
                hintText: 'Search brands...',
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
              SizedBox(height: 20.h),
              Expanded(
                child: FutureBuilder<List<BrandInfo>>(
                  future: _brandsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return const EmptyState(
                        icon: Icons.cloud_off_rounded,
                        title: 'Could not load brands',
                        subtitle: 'Please check your connection and try again.',
                      );
                    }

                    final brands = _filterBrands(snapshot.data ?? []);
                    if (brands.isEmpty) {
                      return EmptyState(
                        icon: Icons.search_off_rounded,
                        title: _searchQuery.isEmpty
                            ? 'No brands yet'
                            : 'No matches found',
                        subtitle: _searchQuery.isEmpty
                            ? 'Add logos to assets/brand_logos/'
                            : 'Try a different search term.',
                      );
                    }

                    return GridView.builder(
                      padding: EdgeInsets.only(top: 4.h, bottom: 110.h),
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14.w,
                        mainAxisSpacing: 14.h,
                        childAspectRatio: 0.92,
                      ),
                      itemCount: brands.length,
                      itemBuilder: (context, index) {
                        return _BrandLogoCard(brand: brands[index]);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandLogoCard extends StatelessWidget {
  const _BrandLogoCard({required this.brand});

  final BrandInfo brand;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      radius: AppRadius.lg,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BrandProductsScreen(brandId: brand.id),
          ),
        );
      },
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              margin: EdgeInsets.all(12.r),
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: SafeAssetImage(assetPath: brand.logoAsset),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 14.h),
            child: Text(
              brand.displayName,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
