import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../models/clothing_item.dart';
import '../painters/overlay_painter.dart';
import '../utils/clothing_image_loader.dart';
import '../services/camera_service.dart';
import '../services/face_detection_service.dart';
import '../services/pose_detection_service.dart';
import '../state/tryon_state.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key, required this.item});

  final ClothingItem item;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final CameraService _cameraService = CameraService();
  final FaceDetectionService _faceService = FaceDetectionService();
  final PoseDetectionService _poseService = PoseDetectionService();

  ui.Image? _clothingImage;
  String? _error;
  bool _loading = true;
  TryOnState? _tryOnState;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tryOnState ??= context.read<TryOnState>();
  }

  Future<void> _bootstrap() async {
    if (kIsWeb) {
      _setError('AR try-on needs a physical Android or iOS phone.');
      return;
    }

    final permission = await Permission.camera.request();
    if (!permission.isGranted) {
      _setError(
        permission.isPermanentlyDenied
            ? 'Camera permission denied. Enable it in Settings.'
            : 'Camera permission is required for AR try-on.',
      );
      return;
    }

    try {
      final image = await ClothingImageLoader.load(
        widget.item.assetPath,
        widget.item.category,
      );
      await _cameraService.initialize();
      if (!mounted) return;

      setState(() {
        _clothingImage = image;
        _loading = false;
      });

      _cameraService.startStream(_onCameraFrame);
    } on CameraException catch (e) {
      _setError('Camera error: ${e.description ?? e.code}');
    } catch (e) {
      _setError('Failed to start try-on: $e');
    }
  }

  void _setError(String message) {
    if (!mounted) return;
    setState(() {
      _error = message;
      _loading = false;
    });
  }

  Future<void> _onCameraFrame(CameraImage image) async {
    final camera = _cameraService.camera;
    final controller = _cameraService.controller;
    final tryOn = _tryOnState;
    if (camera == null || controller == null || tryOn == null || !mounted) {
      return;
    }

    final orientation = controller.value.deviceOrientation;

    if (widget.item.usesFace) {
      final face = await _faceService.processFrame(
        image: image,
        camera: camera,
        deviceOrientation: orientation,
      );
      if (face != null && mounted) {
        tryOn.updateFace(face);
      }
      return;
    }

    final pose = await _poseService.processFrame(
      image: image,
      camera: camera,
      deviceOrientation: orientation,
    );
    if (pose != null && mounted) {
      tryOn.updatePose(pose);
    }
  }

  String _trackingHint(TryOnState tryOn) {
    if (tryOn.isTracking) {
      return 'Trying on: ${widget.item.name}';
    }

    return switch (widget.item.category) {
      ClothingCategory.glasses => 'Point camera at your face for glasses',
      ClothingCategory.hats => 'Point camera at your face for hat placement',
      ClothingCategory.shirts => 'Point camera at your upper body',
      ClothingCategory.pants => 'Step back so hips and legs are visible',
    };
  }

  @override
  void dispose() {
    _cameraService.dispose();
    _faceService.dispose();
    _poseService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF2ACAEA)),
      );
    }

    if (_error != null) {
      return _buildError();
    }

    final controller = _cameraService.controller;
    if (controller == null || !controller.value.isInitialized) {
      return _buildError(message: 'Camera is not available.');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = Size(constraints.maxWidth, constraints.maxHeight);
        final tryOn = context.watch<TryOnState>();
        final isFront =
            _cameraService.camera?.lensDirection == CameraLensDirection.front;

        return Stack(
          fit: StackFit.expand,
          children: [
            CameraPreview(controller),
            if (_clothingImage != null)
              SizedBox.expand(
                child: CustomPaint(
                  painter: OverlayPainter(
                    tryOnState: tryOn,
                    image: _clothingImage!,
                    screenSize: screenSize,
                    isFrontCamera: isFront,
                  ),
                ),
              ),
            SafeArea(
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _trackingHint(tryOn),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildError({String? message}) {
    final text = message ?? _error!;
    final showSettings = text.contains('Settings');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 24),
            if (showSettings)
              ElevatedButton(
                onPressed: openAppSettings,
                child: const Text('Open Settings'),
              ),
            if (showSettings) const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}

void openTryOnCamera(BuildContext context, ClothingItem item) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ChangeNotifierProvider(
        create: (_) => TryOnState(item: item),
        child: CameraScreen(item: item),
      ),
    ),
  );
}
