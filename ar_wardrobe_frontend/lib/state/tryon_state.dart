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
    this.nose,
    this.leftKnee,
    this.rightKnee,
    this.leftAnkle,
    this.rightAnkle,
  });

  final Offset leftShoulder;
  final Offset rightShoulder;
  final Offset leftHip;
  final Offset rightHip;
  final Offset? nose;
  final Offset? leftKnee;
  final Offset? rightKnee;
  final Offset? leftAnkle;
  final Offset? rightAnkle;
  final double imageWidth;
  final double imageHeight;
}

class TryOnState extends ChangeNotifier {
  TryOnState({required this.item});

  final ClothingItem item;
  FaceSnapshot? currentFace;
  PoseSnapshot? currentPose;

  void updateFace(FaceSnapshot? face) {
    currentFace = face;
    notifyListeners();
  }

  void updatePose(PoseSnapshot? pose) {
    currentPose = pose;
    notifyListeners();
  }

  bool get isTracking {
    if (item.usesFace) return currentFace != null;
    if (item.category == ClothingCategory.pants) {
      return currentPose?.leftKnee != null && currentPose?.rightKnee != null;
    }
    return currentPose != null;
  }
}

class FaceSnapshot {
  const FaceSnapshot({
    required this.leftEye,
    required this.rightEye,
    required this.boundingBox,
    required this.headEulerAngleZ,
    required this.imageWidth,
    required this.imageHeight,
  });

  final Offset leftEye;
  final Offset rightEye;
  final Rect boundingBox;
  final double headEulerAngleZ;
  final double imageWidth;
  final double imageHeight;
}
