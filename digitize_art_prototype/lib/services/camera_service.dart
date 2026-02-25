import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraService extends ChangeNotifier {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  String? _error;
  bool _isProcessing = false;

  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  bool get isProcessing => _isProcessing;
  List<CameraDescription> get cameras => _cameras;

  Future<void> initialize() async {
    try {
      // Request camera permission
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        _error = 'Camera permission denied';
        notifyListeners();
        return;
      }

      // Get available cameras
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        _error = 'No cameras found';
        notifyListeners();
        return;
      }

      // Use back camera by default
      final camera = _cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      // Initialize controller with high resolution
      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _controller!.initialize();
      
      // Set flash mode to off
      await _controller!.setFlashMode(FlashMode.off);

      _isInitialized = true;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to initialize camera: $e';
      _isInitialized = false;
      notifyListeners();
    }
  }

  void setProcessing(bool value) {
    _isProcessing = value;
    notifyListeners();
  }

  Future<void> switchCamera() async {
    if (_cameras.length < 2) return;

    try {
      final currentLens = _controller?.description.lensDirection;
      final newCamera = _cameras.firstWhere(
        (cam) => cam.lensDirection != currentLens,
        orElse: () => _cameras.first,
      );

      await _controller?.dispose();
      
      _controller = CameraController(
        newCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _controller!.initialize();
      await _controller!.setFlashMode(FlashMode.off);
      
      notifyListeners();
    } catch (e) {
      _error = 'Failed to switch camera: $e';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
