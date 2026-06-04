import 'dart:math' as math;
import 'dart:ui';

class PreviewCoordinates {
  PreviewCoordinates({
    required this.screenSize,
    required this.imageSize,
    required this.isFrontCamera,
  });

  final Size screenSize;
  final Size imageSize;
  final bool isFrontCamera;

  Offset toScreen(double x, double y) {
    final imageW = imageSize.width;
    final imageH = imageSize.height;
    if (imageW <= 0 || imageH <= 0) return Offset.zero;

    final scale = math.max(
      screenSize.width / imageW,
      screenSize.height / imageH,
    );
    final scaledW = imageW * scale;
    final scaledH = imageH * scale;
    final offsetX = (screenSize.width - scaledW) / 2;
    final offsetY = (screenSize.height - scaledH) / 2;

    var screenX = x * scale + offsetX;
    final screenY = y * scale + offsetY;

    if (isFrontCamera) {
      screenX = screenSize.width - screenX;
    }

    return Offset(screenX, screenY);
  }
}
