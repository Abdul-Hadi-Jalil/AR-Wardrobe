import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/saved_outfit.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_widgets.dart';

class SavedOutfitsScreen extends StatefulWidget {
  const SavedOutfitsScreen({super.key});

  @override
  State<SavedOutfitsScreen> createState() => _SavedOutfitsScreenState();
}

class _SavedOutfitsScreenState extends State<SavedOutfitsScreen> {
  final _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Saved Outfits')),
      body: StreamBuilder<List<SavedOutfit>>(
        stream: _firestoreService.getSavedOutfits(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError) {
            return const EmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Error loading saved outfits',
            );
          }

          final outfits = snapshot.data ?? [];
          if (outfits.isEmpty) {
            return const EmptyState(
              icon: Icons.favorite_border_rounded,
              title: 'No saved outfits yet',
              subtitle: 'Save your favorite outfit combinations.',
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(20.w),
            itemCount: outfits.length,
            itemBuilder: (context, index) {
              final outfit = outfits[index];
              return _OutfitCard(
                outfit: outfit,
                onDelete: () async {
                  await _firestoreService.removeFromSavedOutfits(outfit.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Outfit removed')),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _OutfitCard extends StatelessWidget {
  final SavedOutfit outfit;
  final VoidCallback onDelete;

  const _OutfitCard({required this.outfit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      outfit.outfitName,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Saved on ${outfit.savedAt.toString().split('.')[0]}',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(Icons.delete_outline_rounded,
                      color: AppColors.danger, size: 20.sp),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          SizedBox(
            height: 96.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: outfit.productAssets.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 82.w,
                  margin: EdgeInsets.only(right: 10.w),
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    color: AppColors.surfaceAlt,
                  ),
                  child: SafeAssetImage(
                    assetPath: outfit.productAssets[index],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
