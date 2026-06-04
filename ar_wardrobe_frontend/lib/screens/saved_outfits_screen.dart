import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/saved_outfit.dart';
import '../services/firestore_service.dart';

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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Saved Outfits',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<SavedOutfit>>(
        stream: _firestoreService.getSavedOutfits(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2ACAEA)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading saved outfits',
                style: TextStyle(color: Colors.grey[600], fontSize: 16.sp),
              ),
            );
          }

          final outfits = snapshot.data ?? [];
          if (outfits.isEmpty) {
            return Center(
              child: Text(
                'No saved outfits yet\nSave your favorite outfit combinations',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 16.sp),
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: outfits.length,
            itemBuilder: (context, index) {
              final outfit = outfits[index];
              return _OutfitCard(
                outfit: outfit,
                onDelete: () async {
                  await _firestoreService.removeFromSavedOutfits(outfit.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Outfit removed')),
                  );
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

  const _OutfitCard({
    required this.outfit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    outfit.outfitName,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: onDelete,
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              'Saved on ${outfit.savedAt.toString().split('.')[0]}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12.sp),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              height: 100.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: outfit.productAssets.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: Container(
                      width: 80.w,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.r),
                        color: Colors.grey[100],
                      ),
                      child: Image.asset(
                        outfit.productAssets[index],
                        fit: BoxFit.cover,
                      ),
                    ),
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
