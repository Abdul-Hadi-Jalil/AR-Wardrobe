import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/clothing_item.dart';
import '../state/tryon_state.dart';
import '../utils/preview_coordinates.dart';

class OverlayPainter extends CustomPainter {
  OverlayPainter({
    required this.tryOnState,
    required this.image,
    required this.screenSize,
    required this.isFrontCamera,
  });

  final TryOnState tryOnState;
  final ui.Image image;
  final Size screenSize;
  final bool isFrontCamera;

  static Future<ui.Image> loadClothingImage(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  @override
  void paint(Canvas canvas, Size size) {
    switch (tryOnState.item.category) {
      case ClothingCategory.glasses:
        _paintGlasses(canvas);
      case ClothingCategory.hats:
        _paintHat(canvas);
      case ClothingCategory.shirts:
        _paintShirt(canvas);
    }
  }

  void _paintGlasses(Canvas canvas) {
    final face = tryOnState.currentFace;
    if (face == null) return;

    final coords = _coordsFor(face.imageWidth, face.imageHeight);
    final leftEye = coords.toScreen(face.leftEye.dx, face.leftEye.dy);
    final rightEye = coords.toScreen(face.rightEye.dx, face.rightEye.dy);

    const padding = 14.0;
    final rect = _rectFromPoints(leftEye, rightEye, padX: padding, padY: padding);
    _paintRotated(canvas, rect, face.headEulerAngleZ);
  }

  void _paintHat(Canvas canvas) {
    final face = tryOnState.currentFace;
    if (face == null) return;

    final coords = _coordsFor(face.imageWidth, face.imageHeight);
    final topLeft = coords.toScreen(
      face.boundingBox.left,
      face.boundingBox.top,
    );
    final bottomRight = coords.toScreen(
      face.boundingBox.right,
      face.boundingBox.bottom,
    );
    final faceRect = Rect.fromPoints(topLeft, bottomRight);
    final width = faceRect.width * 1.2;
    final height = width * (image.height / image.width);

    _paintImage(
      canvas,
      Rect.fromLTWH(
        faceRect.center.dx - width / 2,
        faceRect.top - height,
        width,
        height,
      ),
    );
  }

  void _paintShirt(Canvas canvas) {
    final pose = tryOnState.currentPose;
    if (pose == null) return;

    final coords = _coordsFor(pose.imageWidth, pose.imageHeight);
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

    _paintImage(
      canvas,
      Rect.fromLTWH(
        left - width * 0.15,
        shoulderY - height * 0.05,
        width,
        height,
      ),
    );
  }

  PreviewCoordinates _coordsFor(double imageW, double imageH) {
    return PreviewCoordinates(
      screenSize: screenSize,
      imageSize: Size(imageW, imageH),
      isFrontCamera: isFrontCamera,
    );
  }

  Rect _rectFromPoints(
    Offset a,
    Offset b, {
    double padX = 0,
    double padY = 0,
  }) {
    final left = a.dx < b.dx ? a.dx : b.dx;
    final top = a.dy < b.dy ? a.dy : b.dy;
    final right = a.dx > b.dx ? a.dx : b.dx;
    final bottom = a.dy > b.dy ? a.dy : b.dy;
    return Rect.fromLTRB(
      left - padX,
      top - padY,
      right + padX,
      bottom + padY,
    );
  }

  void _paintRotated(Canvas canvas, Rect rect, double angleDegrees) {
    if (rect.width <= 0 || rect.height <= 0) return;

    canvas.save();
    final center = rect.center;
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angleDegrees * (3.1415926535 / 180));
    canvas.translate(-center.dx, -center.dy);
    _paintImage(canvas, rect);
    canvas.restore();
  }

  void _paintImage(Canvas canvas, Rect rect) {
    if (rect.width <= 0 || rect.height <= 0) return;
    paintImage(
      canvas: canvas,
      rect: rect,
      image: image,
      fit: BoxFit.fill,
      filterQuality: FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(covariant OverlayPainter oldDelegate) => true;
}
