import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/clothing_item.dart';
import '../state/tryon_state.dart';
import '../utils/preview_coordinates.dart';

class OverlayPainter extends CustomPainter {
  OverlayPainter({
    required this.tryOnState,
    required this.imageCache,
    required this.screenSize,
    required this.isFrontCamera,
  });

  final TryOnState tryOnState;
  final Map<String, ui.Image> imageCache;
  final Size screenSize;
  final bool isFrontCamera;

  static Future<Map<String, ui.Image>> loadShirtImage() async {
    final data = await rootBundle.load(ClothingItem.jClothesShirtPath);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return {ClothingItem.jClothesShirtPath: frame.image};
  }

  @override
  void paint(Canvas canvas, Size size) {
    final pose = tryOnState.currentPose;
    if (pose == null) return;

    final shirt = imageCache[ClothingItem.jClothesShirtPath];
    if (shirt == null) return;

    final coords = PreviewCoordinates(
      screenSize: screenSize,
      imageSize: Size(pose.imageWidth, pose.imageHeight),
      isFrontCamera: isFrontCamera,
    );

    final leftShoulder = coords.toScreen(
      pose.leftShoulder.dx,
      pose.leftShoulder.dy,
    );
    final rightShoulder = coords.toScreen(
      pose.rightShoulder.dx,
      pose.rightShoulder.dy,
    );
    final leftHip = coords.toScreen(pose.leftHip.dx, pose.leftHip.dy);
    final rightHip = coords.toScreen(pose.rightHip.dx, pose.rightHip.dy);

    final shoulderY = (leftShoulder.dy + rightShoulder.dy) / 2;
    final hipY = (leftHip.dy + rightHip.dy) / 2;
    final width = (rightShoulder.dx - leftShoulder.dx).abs() * 1.35;
    final height = (hipY - shoulderY).abs() * 1.15;
    if (width < 20 || height < 20) return;

    final left = leftShoulder.dx < rightShoulder.dx
        ? leftShoulder.dx
        : rightShoulder.dx;

    final rect = Rect.fromLTWH(
      left - width * 0.15,
      shoulderY - height * 0.05,
      width,
      height,
    );

    paintImage(
      canvas: canvas,
      rect: rect,
      image: shirt,
      fit: BoxFit.fill,
      filterQuality: FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(covariant OverlayPainter oldDelegate) => true;
}
