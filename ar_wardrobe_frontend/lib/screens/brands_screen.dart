import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/brand_catalog.dart';
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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Brands',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search brands...',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16.sp,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey[400],
                    size: 24.w,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 16.h,
                  ),
                ),
              ),
            ),
            SizedBox(height: 24.h),
            Expanded(
              child: FutureBuilder<List<BrandInfo>>(
                future: _brandsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2ACAEA),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Could not load brands',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16.sp,
                        ),
                      ),
                    );
                  }

                  final brands = _filterBrands(snapshot.data ?? []);
                  if (brands.isEmpty) {
                    return Center(
                      child: Text(
                        _searchQuery.isEmpty
                            ? 'Add logos to assets/brand_logos/'
                            : 'No brands match your search',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14.sp,
                        ),
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: EdgeInsets.only(bottom: 24.h),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12.w,
                      mainAxisSpacing: 12.h,
                      childAspectRatio: 0.95,
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
    );
  }
}

class _BrandLogoCard extends StatelessWidget {
  const _BrandLogoCard({required this.brand});

  final BrandInfo brand;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BrandProductsScreen(brandId: brand.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          decoration: BoxDecoration(
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
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(16.r),
                  child: Image.asset(
                    brand.logoAsset,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(12.r),
                  ),
                ),
                child: Text(
                  brand.displayName,
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
