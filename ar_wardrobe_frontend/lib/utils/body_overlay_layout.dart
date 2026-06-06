import 'package:flutter/material.dart';

import '../state/tryon_state.dart';
import 'preview_coordinates.dart';

/// Computes on-screen clothing rects from pose landmarks and body proportions.
class BodyOverlayLayout {
  BodyOverlayLayout._();

  static Rect? shirtRect({
    required PoseSnapshot pose,
    required PreviewCoordinates coords,
  }) {
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
    final shoulderWidth = (rightShoulder.dx - leftShoulder.dx).abs();
    final hipWidth = (rightHip.dx - leftHip.dx).abs();
    final torsoHeight = (hipY - shoulderY).abs();

    if (torsoHeight < 20 || shoulderWidth < 20) return null;

    final bodyCenterX = _centerX(
      leftShoulder.dx,
      rightShoulder.dx,
      leftHip.dx,
      rightHip.dx,
    );

    // Neck line: between nose and shoulders (collar sits here).
    final neckY = _neckY(
      coords: coords,
      pose: pose,
      shoulderY: shoulderY,
      torsoHeight: torsoHeight,
    );

    final shirtTop = neckY;
    final shirtBottom = hipY + torsoHeight * 0.06;
    final shirtHeight = shirtBottom - shirtTop;
    final shirtWidth = _bodyWidth(shoulderWidth, hipWidth) * 1.22;

    if (shirtWidth < 20 || shirtHeight < 20) return null;

    return Rect.fromLTWH(
      bodyCenterX - shirtWidth / 2,
      shirtTop,
      shirtWidth,
      shirtHeight,
    );
  }

  static Rect? pantsRect({
    required PoseSnapshot pose,
    required PreviewCoordinates coords,
  }) {
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

    final hipY = (leftHip.dy + rightHip.dy) / 2;
    final shoulderY = (leftShoulder.dy + rightShoulder.dy) / 2;
    final hipWidth = (rightHip.dx - leftHip.dx).abs();
    final torsoHeight = (hipY - shoulderY).abs();

    if (hipWidth < 20) return null;

    final bodyCenterX = _centerX(
      leftShoulder.dx,
      rightShoulder.dx,
      leftHip.dx,
      rightHip.dx,
    );

    // Waist / mid-body — top of pants at hip line.
    final pantsTop = hipY - torsoHeight * 0.04;

    final pantsBottom = _pantsBottomY(coords: coords, pose: pose, hipY: hipY);
    if (pantsBottom == null) return null;

    final pantsHeight = pantsBottom - pantsTop;
    final pantsWidth = hipWidth * 1.16;

    if (pantsHeight < 20) return null;

    return Rect.fromLTWH(
      bodyCenterX - pantsWidth / 2,
      pantsTop,
      pantsWidth,
      pantsHeight,
    );
  }

  static double _neckY({
    required PreviewCoordinates coords,
    required PoseSnapshot pose,
    required double shoulderY,
    required double torsoHeight,
  }) {
    if (pose.nose != null) {
      final nose = coords.toScreen(pose.nose!.dx, pose.nose!.dy);
      // Collar sits ~60% of the way from nose down to shoulders.
      return nose.dy + (shoulderY - nose.dy) * 0.62;
    }
    return shoulderY - torsoHeight * 0.14;
  }

  static double? _pantsBottomY({
    required PreviewCoordinates coords,
    required PoseSnapshot pose,
    required double hipY,
  }) {
    final leftKnee = pose.leftKnee;
    final rightKnee = pose.rightKnee;
    final leftAnkle = pose.leftAnkle;
    final rightAnkle = pose.rightAnkle;

    if (leftKnee != null && rightKnee != null) {
      final lk = coords.toScreen(leftKnee.dx, leftKnee.dy);
      final rk = coords.toScreen(rightKnee.dx, rightKnee.dy);
      final kneeY = (lk.dy + rk.dy) / 2;

      if (leftAnkle != null && rightAnkle != null) {
        final la = coords.toScreen(leftAnkle.dx, leftAnkle.dy);
        final ra = coords.toScreen(rightAnkle.dx, rightAnkle.dy);
        final ankleY = (la.dy + ra.dy) / 2;
        // End mid-shin — covers legs, stops above feet.
        return kneeY + (ankleY - kneeY) * 0.72;
      }

      // Extend slightly past knees when ankles aren't visible.
      return kneeY + (kneeY - hipY) * 0.18;
    }

    return null;
  }

  static double _bodyWidth(double shoulderWidth, double hipWidth) {
    return shoulderWidth > hipWidth ? shoulderWidth : hipWidth;
  }

  static double _centerX(
    double leftShoulderX,
    double rightShoulderX,
    double leftHipX,
    double rightHipX,
  ) {
    final shoulderCenter = (leftShoulderX + rightShoulderX) / 2;
    final hipCenter = (leftHipX + rightHipX) / 2;
    return (shoulderCenter + hipCenter) / 2;
  }
}
