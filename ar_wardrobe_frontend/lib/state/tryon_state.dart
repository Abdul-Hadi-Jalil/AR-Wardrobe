import 'package:flutter/material.dart';

import '../models/clothing_item.dart';

class PoseSnapshot {
  const PoseSnapshot({
    required this.leftShoulder,
    required this.rightShoulder,
    required this.leftHip,
    required this.rightHip,
    required this.imageWidth,
    required this.imageHeight,
  });

  final Offset leftShoulder;
  final Offset rightShoulder;
  final Offset leftHip;
  final Offset rightHip;
  final double imageWidth;
  final double imageHeight;
}

class TryOnState extends ChangeNotifier {
  TryOnState({required this.item});

  final ClothingItem item;
  PoseSnapshot? currentPose;

  void updatePose(PoseSnapshot? pose) {
    currentPose = pose;
    notifyListeners();
  }
}
