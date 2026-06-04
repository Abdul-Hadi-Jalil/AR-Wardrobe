import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../state/tryon_state.dart';
import 'mlkit_input_image.dart';

class PoseDetectionService {
  PoseDetectionService()
      : _detector = PoseDetector(
          options: PoseDetectorOptions(
            model: PoseDetectionModel.base,
            mode: PoseDetectionMode.stream,
          ),
        );

  final PoseDetector _detector;
  int _frameCount = 0;
  bool _isProcessing = false;

  Future<PoseSnapshot?> processFrame({
    required CameraImage image,
    required CameraDescription camera,
    required DeviceOrientation deviceOrientation,
  }) async {
    _frameCount++;
    if (_frameCount % 2 != 0 || _isProcessing) return null;

    _isProcessing = true;
    try {
      final inputImage = cameraImageToInputImage(
        image: image,
        camera: camera,
        deviceOrientation: deviceOrientation,
      );
      if (inputImage == null) return null;

      final poses = await _detector.processImage(inputImage);
      if (poses.isEmpty) return null;

      final pose = poses.first;
      final ls = pose.landmarks[PoseLandmarkType.leftShoulder];
      final rs = pose.landmarks[PoseLandmarkType.rightShoulder];
      final lh = pose.landmarks[PoseLandmarkType.leftHip];
      final rh = pose.landmarks[PoseLandmarkType.rightHip];

      if (ls == null ||
          rs == null ||
          lh == null ||
          rh == null ||
          ls.likelihood < 0.5 ||
          rs.likelihood < 0.5 ||
          lh.likelihood < 0.5 ||
          rh.likelihood < 0.5) {
        return null;
      }

      final visionSize = visionImageSize(inputImage);

      return PoseSnapshot(
        leftShoulder: Offset(ls.x, ls.y),
        rightShoulder: Offset(rs.x, rs.y),
        leftHip: Offset(lh.x, lh.y),
        rightHip: Offset(rh.x, rh.y),
        imageWidth: visionSize.width,
        imageHeight: visionSize.height,
      );
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> dispose() => _detector.close();
}
