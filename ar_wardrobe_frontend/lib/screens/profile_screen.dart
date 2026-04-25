import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          // Header Section with Profile
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF2ACAEA),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(30.r),
              ),
            ),
            child: Column(
              children: [
                SizedBox(height: 60.h),
                CircleAvatar(
                  radius: 50.r,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 60.w,
                    color: Colors.grey[400],
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  'NAME : XYZ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'EMAIL: abc@gmail.com',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: 40.h),
              ],
            ),
          ),

          // Stats Section
          Container(
            transform: Matrix4.translationValues(0, -20.h, 0),
            margin: EdgeInsets.symmetric(horizontal: 20.w),
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Saved Items', '12'),
                _buildStatItem('Tried Items', '34'),
                _buildStatItem('Orders', '5'),
              ],
            ),
          ),

          // Menu Items
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.favorite,
                    iconColor: Colors.red,
                    title: 'Saved Outfits',
                    onTap: () {},
                  ),
                  SizedBox(height: 16.h),
                  _buildMenuItem(
                    icon: Icons.shopping_bag,
                    iconColor: Colors.brown,
                    title: 'Orders',
                    onTap: () {},
                  ),
                  SizedBox(height: 16.h),
                  _buildMenuItem(
                    icon: Icons.settings,
                    iconColor: Colors.grey,
                    title: 'Settings',
                    onTap: () {},
                  ),
                  SizedBox(height: 16.h),
                  _buildMenuItem(
                    icon: Icons.lock,
                    iconColor: Colors.amber,
                    title: 'Privacy and Security',
                    onTap: () {},
                  ),
                  SizedBox(height: 16.h),
                  _buildMenuItem(
                    icon: Icons.logout,
                    iconColor: Colors.grey,
                    title: 'Logout',
                    onTap: () {},
                  ),
                  const Spacer(),
                  SizedBox(height: 100.h), // Bottom navigation padding
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.black,
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 40.w,
          height: 40.h,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, color: iconColor, size: 24.w),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.black,
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey[400],
          size: 16.w,
        ),
        onTap: onTap,
      ),
    );
  }
}
