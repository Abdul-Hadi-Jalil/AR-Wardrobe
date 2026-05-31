import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../state/tryon_state.dart';
import 'mlkit_input_image.dart';

class FaceDetectionService {
  FaceDetectionService()
      : _detector = FaceDetector(
          options: FaceDetectorOptions(
            enableContours: true,
            enableLandmarks: true,
            performanceMode: FaceDetectorMode.fast,
          ),
        );

  final FaceDetector _detector;
  int _frameCount = 0;
  bool _isProcessing = false;

  Future<FaceSnapshot?> processFrame({
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

      final faces = await _detector.processImage(inputImage);
      if (faces.isEmpty) return null;

      final face = faces.first;
      final leftEye = face.landmarks[FaceLandmarkType.leftEye]?.position;
      final rightEye = face.landmarks[FaceLandmarkType.rightEye]?.position;
      if (leftEye == null || rightEye == null) return null;

      final visionSize = visionImageSize(inputImage);

      return FaceSnapshot(
        leftEye: Offset(leftEye.x.toDouble(), leftEye.y.toDouble()),
        rightEye: Offset(rightEye.x.toDouble(), rightEye.y.toDouble()),
        boundingBox: Rect.fromLTRB(
          face.boundingBox.left.toDouble(),
          face.boundingBox.top.toDouble(),
          face.boundingBox.right.toDouble(),
          face.boundingBox.bottom.toDouble(),
        ),
        headEulerAngleZ: face.headEulerAngleZ ?? 0,
        imageWidth: visionSize.width,
        imageHeight: visionSize.height,
      );
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> dispose() => _detector.close();
}
