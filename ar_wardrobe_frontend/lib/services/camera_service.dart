import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

class CameraService {
  CameraController? _controller;
  CameraDescription? _camera;

  CameraController? get controller => _controller;
  CameraDescription? get camera => _camera;
  bool get isInitialized => _controller?.value.isInitialized ?? false;

  Future<void> initialize() async {
    if (kIsWeb) {
      throw UnsupportedError('AR try-on requires a physical Android or iOS device.');
    }

    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw CameraException('no_camera', 'No camera found on this device.');
    }

    _camera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    final formatAttempts = <ImageFormatGroup?>[
      if (Platform.isAndroid) ImageFormatGroup.yuv420,
      if (Platform.isIOS) ImageFormatGroup.bgra8888,
      null,
    ];

    Object? lastError;
    for (final format in formatAttempts) {
      await _controller?.dispose();
      _controller = CameraController(
        _camera!,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: format,
      );
      try {
        await _controller!.initialize();
        return;
      } catch (e) {
        lastError = e;
      }
    }

    throw CameraException('init_failed', 'Could not open camera: $lastError');
  }

  void startStream(void Function(CameraImage image) onFrame) {
    if (!isInitialized) return;
    _controller!.startImageStream(onFrame);
  }

  void stopStream() {
    if (_controller?.value.isStreamingImages ?? false) {
      _controller!.stopImageStream();
    }
  }

  Future<void> dispose() async {
    stopStream();
    await _controller?.dispose();
    _controller = null;
  }
}
