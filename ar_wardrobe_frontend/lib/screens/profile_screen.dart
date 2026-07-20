import 'package:ar_wardrobe_frontend/screens/edit_profile_screen.dart';
import 'package:ar_wardrobe_frontend/screens/orders_screen.dart';
import 'package:ar_wardrobe_frontend/screens/saved_outfits_screen.dart';
import 'package:ar_wardrobe_frontend/screens/terms_consent_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  int _savedItemsCount = 0;
  int _ordersCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    final savedOutfits = await _firestoreService.getSavedOutfits().first;
    final orders = await _firestoreService.getOrders().first;

    if (mounted) {
      setState(() {
        _savedItemsCount = savedOutfits.length;
        _ordersCount = orders.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.userChanges(),
        builder: (context, snapshot) {
          final user = snapshot.data ?? FirebaseAuth.instance.currentUser;
          final displayName = user?.displayName?.trim().isNotEmpty == true
              ? user!.displayName!
              : 'Your Name';
          final email = user?.email ?? 'your.email@domain.com';
          final initials = displayName
              .split(' ')
              .where((part) => part.isNotEmpty)
              .map((part) => part[0])
              .take(2)
              .join()
              .toUpperCase();

          return SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(top: 60.h, bottom: 56.h),
                  decoration: BoxDecoration(
                    gradient: AppGradients.brand,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(36.r),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.5),
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 46.r,
                          backgroundColor: Colors.white,
                          child: Text(
                            initials,
                            style: TextStyle(
                              fontSize: 34.sp,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        displayName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        email,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                Transform.translate(
                  offset: Offset(0, -28.h),
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 20.w),
                    padding: EdgeInsets.symmetric(vertical: 20.h),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      boxShadow: AppShadows.card,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                              'Saved Items', '$_savedItemsCount'),
                        ),
                        Container(
                          width: 1,
                          height: 36.h,
                          color: AppColors.border,
                        ),
                        Expanded(
                          child: _buildStatItem('Orders', '$_ordersCount'),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 120.h),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        icon: Icons.favorite_rounded,
                        iconColor: const Color(0xFFFF5C8A),
                        title: 'Saved Outfits',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SavedOutfitsScreen(),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 14.h),
                      _buildMenuItem(
                        icon: Icons.shopping_bag_rounded,
                        iconColor: AppColors.accent,
                        title: 'My Orders',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const OrdersScreen(),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 14.h),
                      _buildMenuItem(
                        icon: Icons.edit_rounded,
                        iconColor: AppColors.primary,
                        title: 'Edit Profile',
                        onTap: () async {
                          await showDialog(
                            context: context,
                            builder: (_) => const EditProfileScreen(),
                          );
                        },
                      ),
                      SizedBox(height: 14.h),
                      _buildMenuItem(
                        icon: Icons.privacy_tip_outlined,
                        iconColor: const Color(0xFF6366F1),
                        title: 'Terms & Privacy',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TermsConsentScreen(),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 14.h),
                      _buildMenuItem(
                        icon: Icons.logout_rounded,
                        iconColor: AppColors.textSecondary,
                        title: 'Logout',
                        onTap: () {
                          FirebaseAuth.instance.signOut();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 24.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13.sp,
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
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: AppShadows.soft,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            child: Row(
              children: [
                Container(
                  width: 42.w,
                  height: 42.w,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(icon, color: iconColor, size: 22.sp),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    color: AppColors.textMuted, size: 15.sp),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
