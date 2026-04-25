import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OutfitBuilderScreen extends StatelessWidget {
  const OutfitBuilderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          children: [
            Text(
              'OUTFIT BUILDER SCREEN',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'Outfit Builder',
              style: TextStyle(
                color: Colors.black,
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          children: [
            // Mannequin Section
            Container(
              height: 300.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.accessibility_new,
                  size: 120.w,
                  color: Colors.grey[400],
                ),
              ),
            ),
            SizedBox(height: 24.h),

            // Category Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCategoryButton('Tops'),
                _buildCategoryButton('Bottoms'),
                _buildCategoryButton('Shoes'),
                _buildCategoryButton(''), // Empty button
              ],
            ),
            SizedBox(height: 24.h),

            // Clothing Items Section
            Text(
              'Select Items',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            SizedBox(
              height: 120.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 6,
                itemBuilder: (context, index) {
                  final items = [
                    'Jacket',
                    'Tee',
                    'Jeans',
                    'Cap',
                    'Shoes',
                    'Watch',
                  ];
                  return _buildClothingItem(items[index]);
                },
              ),
            ),
            SizedBox(height: 32.h),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 56.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2ACAEA),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'Save Outfit',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Container(
                    height: 56.h,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'Reset',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 100.h), // Bottom navigation padding
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryButton(String title) {
    return Container(
      width: 70.w,
      height: 40.h,
      decoration: BoxDecoration(
        color: const Color(0xFF2ACAEA),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Center(
        child: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildClothingItem(String itemName) {
    return Container(
      width: 80.w,
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40.w,
            height: 40.h,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              _getIconForItem(itemName),
              size: 24.w,
              color: Colors.grey[400],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            itemName,
            style: TextStyle(
              color: Colors.black87,
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  IconData _getIconForItem(String itemName) {
    switch (itemName.toLowerCase()) {
      case 'jacket':
        return Icons.checkroom;
      case 'tee':
        return Icons.style;
      case 'jeans':
        return Icons.dry_cleaning;
      case 'cap':
        return Icons.face;
      case 'shoes':
        return Icons.follow_the_signs_rounded;
      case 'watch':
        return Icons.watch;
      default:
        return Icons.category;
    }
  }
}
