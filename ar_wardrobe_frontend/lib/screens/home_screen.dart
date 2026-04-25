import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: EdgeInsets.only(left: 16.w),
          child: Text(
            'Home',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        leadingWidth: 80.w,
        title: const Text(
          'AR Wardrobe',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20.h),
            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search outfits, brands...',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16.sp,
                  ),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 24.w),
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
            SizedBox(height: 32.h),
            
            // Categories Section
            Text(
              'Categories',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                _buildCategoryButton('Men'),
                SizedBox(width: 12.w),
                _buildCategoryButton('Women'),
                SizedBox(width: 12.w),
                _buildCategoryButton('Kids'),
              ],
            ),
            SizedBox(height: 32.h),
            
            // Featured Outfits Section
            Text(
              'Featured Outfits',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            SizedBox(
              height: 200.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 4,
                itemBuilder: (context, index) {
                  return _buildFeaturedOutfitCard(
                    index == 0 ? 'Casual Jacket' : 'Denim Jacket',
                    index == 0 ? '\$59' : '\$39',
                    index == 0 ? 'jacket' : 'denim',
                  );
                },
              ),
            ),
            SizedBox(height: 32.h),
            
            // Popular Brands Section
            Text(
              'Popular Brands',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            SizedBox(
              height: 80.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 8,
                itemBuilder: (context, index) {
                  final brands = ['J.', 'KHAADI', 'APPHIR', 'ENGINE', 'NIKE', 'ADIDAS', 'PUMA', 'REEBOK'];
                  return _buildBrandCard(brands[index]);
                },
              ),
            ),
            SizedBox(height: 100.h), // Bottom navigation padding
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryButton(String title) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: const Color(0xFF6B46C1)),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: const Color(0xFF6B46C1),
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildFeaturedOutfitCard(String name, String price, String type) {
    return Container(
      width: 150.w,
      margin: EdgeInsets.only(right: 12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120.h,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
              color: Colors.grey[200],
            ),
            child: Icon(
              type == 'jacket' ? Icons.checkroom : Icons.style,
              size: 48.w,
              color: Colors.grey[400],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(12.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  price,
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandCard(String brandName) {
    return Container(
      width: 80.w,
      height: 80.h,
      margin: EdgeInsets.only(right: 12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          brandName,
          style: TextStyle(
            color: Colors.black87,
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
