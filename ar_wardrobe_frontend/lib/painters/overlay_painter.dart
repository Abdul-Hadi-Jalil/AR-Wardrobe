import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/clothing_item.dart';
import '../state/tryon_state.dart';
import '../utils/body_overlay_layout.dart';
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

  double get _imageAspect => image.width / image.height;

  @override
  void paint(Canvas canvas, Size size) {
    switch (tryOnState.item.category) {
      case ClothingCategory.glasses:
        _paintGlasses(canvas);
      case ClothingCategory.hats:
        _paintHat(canvas);
      case ClothingCategory.shirts:
        _paintShirt(canvas);
      case ClothingCategory.pants:
        _paintPants(canvas);
    }
  }

  void _paintGlasses(Canvas canvas) {
    final face = tryOnState.currentFace;
    if (face == null) return;

    final coords = _coordsFor(face.imageWidth, face.imageHeight);
    final leftEye = coords.toScreen(face.leftEye.dx, face.leftEye.dy);
    final rightEye = coords.toScreen(face.rightEye.dx, face.rightEye.dy);

    final eyeCenter = Offset(
      (leftEye.dx + rightEye.dx) / 2,
      (leftEye.dy + rightEye.dy) / 2,
    );
    final eyeDistance = (rightEye - leftEye).distance;
    final width = eyeDistance * 2.5;
    final height = width / _imageAspect;

    final rect = Rect.fromCenter(
      center: eyeCenter,
      width: width,
      height: height,
    );

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
    final faceHeight = faceRect.height;
    final width = faceRect.width * 1.15;
    final height = width / _imageAspect;

    // Brim sits on forehead and overlaps the top of the face box to cover hair.
    final hatBottom = faceRect.top + faceHeight * 0.28;

    _paintContained(
      canvas,
      Rect.fromLTWH(
        faceRect.center.dx - width / 2,
        hatBottom - height,
        width,
        height,
      ),
      alignment: Alignment.bottomCenter,
    );
  }

  void _paintShirt(Canvas canvas) {
    final pose = tryOnState.currentPose;
    if (pose == null) return;

    final coords = _coordsFor(pose.imageWidth, pose.imageHeight);
    final rect = BodyOverlayLayout.shirtRect(pose: pose, coords: coords);
    if (rect == null) return;

    _paintContained(canvas, rect, alignment: Alignment.topCenter);
  }

  void _paintPants(Canvas canvas) {
    final pose = tryOnState.currentPose;
    if (pose == null) return;

    final coords = _coordsFor(pose.imageWidth, pose.imageHeight);
    final rect = BodyOverlayLayout.pantsRect(pose: pose, coords: coords);
    if (rect == null) return;

    _paintContained(canvas, rect, alignment: Alignment.topCenter);
  }

  PreviewCoordinates _coordsFor(double imageW, double imageH) {
    return PreviewCoordinates(
      screenSize: screenSize,
      imageSize: Size(imageW, imageH),
      isFrontCamera: isFrontCamera,
    );
  }

  void _paintRotated(Canvas canvas, Rect rect, double angleDegrees) {
    if (rect.width <= 0 || rect.height <= 0) return;

    canvas.save();
    final center = rect.center;
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angleDegrees * (3.1415926535 / 180));
    canvas.translate(-center.dx, -center.dy);
    _paintContained(canvas, rect);
    canvas.restore();
  }

  void _paintContained(
    Canvas canvas,
    Rect rect, {
    Alignment alignment = Alignment.center,
  }) {
    if (rect.width <= 0 || rect.height <= 0) return;

    paintImage(
      canvas: canvas,
      rect: rect,
      image: image,
      fit: BoxFit.contain,
      alignment: alignment,
      filterQuality: FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(covariant OverlayPainter oldDelegate) => true;
}
