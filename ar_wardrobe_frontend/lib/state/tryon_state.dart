import 'package:flutter/material.dart';

import '../models/clothing_item.dart';

class PoseSnapshot {
  const PoseSnapshot({
    required this.leftShoulder,
    required this.rightShoulder,
    required this.leftHip,
    required this.rightHip,
    required this.leftKnee,
    required this.rightKnee,
    required this.imageWidth,
    required this.imageHeight,
  });

  final Offset leftShoulder;
  final Offset rightShoulder;
  final Offset leftHip;
  final Offset rightHip;
  final Offset leftKnee;
  final Offset rightKnee;
  final double imageWidth;
  final double imageHeight;
}

class TryOnState extends ChangeNotifier {
  ClothingCategory selectedCategory = ClothingCategory.shirts;
  int selectedItemIndex = 0;
  PoseSnapshot? currentPose;

  void updatePose(PoseSnapshot? pose) {
    currentPose = pose;
    notifyListeners();
  }

  ClothingItem get selectedItem => ClothingItem.shirt;
}
