import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart' show DeviceOrientation;
import 'package:flutter/widgets.dart' show Size;
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

InputImage? cameraImageToInputImage({
  required CameraImage image,
  required CameraDescription camera,
  required DeviceOrientation deviceOrientation,
}) {
  final rotation = _rotation(camera, deviceOrientation);
  if (rotation == null) return null;

  if (Platform.isAndroid) {
    return InputImage.fromBytes(
      bytes: _yuv420ToNv21(image),
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.nv21,
        bytesPerRow: image.width,
      ),
    );
  }

  if (Platform.isIOS) {
    if (image.planes.isEmpty) return null;
    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.bgra8888,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  return null;
}

Size visionImageSize(InputImage input) {
  final meta = input.metadata!;
  final w = meta.size.width;
  final h = meta.size.height;
  switch (meta.rotation) {
    case InputImageRotation.rotation90deg:
    case InputImageRotation.rotation270deg:
      return Size(h, w);
    default:
      return Size(w, h);
  }
}

InputImageRotation? _rotation(
  CameraDescription camera,
  DeviceOrientation deviceOrientation,
) {
  final orientations = <DeviceOrientation, int>{
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  if (Platform.isIOS) {
    return InputImageRotationValue.fromRawValue(camera.sensorOrientation);
  }

  if (Platform.isAndroid) {
    var compensation = orientations[deviceOrientation];
    if (compensation == null) return null;

    if (camera.lensDirection == CameraLensDirection.front) {
      compensation = (camera.sensorOrientation + compensation) % 360;
    } else {
      compensation = (camera.sensorOrientation - compensation + 360) % 360;
    }
    return InputImageRotationValue.fromRawValue(compensation);
  }

  return InputImageRotation.rotation0deg;
}

Uint8List _yuv420ToNv21(CameraImage image) {
  final yPlane = image.planes[0];
  final uPlane = image.planes[1];
  final vPlane = image.planes[2];

  final width = image.width;
  final height = image.height;
  final ySize = width * height;
  final uvSize = width * height ~/ 2;
  final nv21 = Uint8List(ySize + uvSize);

  var yIndex = 0;
  for (var row = 0; row < height; row++) {
    for (var col = 0; col < width; col++) {
      nv21[yIndex++] = yPlane.bytes[row * yPlane.bytesPerRow + col];
    }
  }

  final uvRowStride = uPlane.bytesPerRow;
  final uvPixelStride = uPlane.bytesPerPixel ?? 1;
  var uvIndex = ySize;

  for (var row = 0; row < height ~/ 2; row++) {
    for (var col = 0; col < width ~/ 2; col++) {
      final offset = row * uvRowStride + col * uvPixelStride;
      nv21[uvIndex++] = vPlane.bytes[offset];
      nv21[uvIndex++] = uPlane.bytes[offset];
    }
  }

  return nv21;
}
