// lib/shared/services/camera_service.dart
import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service for managing camera operations
class CameraService {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  
  // Lighting quality threshold
  static const double kGoodLightingThreshold = 100.0;
  static const double kMinLightingThreshold = 50.0;

  /// Initialize camera service
  Future<void> initialize({
    ResolutionPreset resolution = ResolutionPreset.veryHigh,
    CameraLensDirection direction = CameraLensDirection.back,
  }) async {
    try {
      _cameras = await availableCameras();
      
      if (_cameras == null || _cameras!.isEmpty) {
        throw CameraException('NoCameraAvailable', 'No cameras found on device');
      }

      final camera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == direction,
        orElse: () => _cameras!.first,
      );

      _controller = CameraController(
        camera,
        resolution,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      
      // Set focus mode to continuous for artwork scanning
      await _controller!.setFocusMode(FocusMode.auto);
      
      // Enable flash by default off
      await _controller!.setFlashMode(FlashMode.off);
      
      _isInitialized = true;
      
      debugPrint('✅ Camera initialized: ${camera.name}');
    } catch (e) {
      debugPrint('❌ Camera initialization failed: $e');
      rethrow;
    }
  }

  /// Get camera controller
  CameraController? get controller => _controller;

  /// Check if camera is ready
  bool get isReady => _isInitialized && _controller != null && _controller!.value.isInitialized;

  /// Capture image with quality checks
  Future<CaptureResult> captureImage({
    bool checkBlur = true,
    bool checkLighting = true,
  }) async {
    if (!isReady) {
      throw CameraException('NotInitialized', 'Camera not initialized');
    }

    try {
      // Lock focus before capture for better sharpness
      await _controller!.setFocusMode(FocusMode.locked);
      
      // Small delay for focus lock
      await Future.delayed(const Duration(milliseconds: 200));
      
      final XFile image = await _controller!.takePicture();
      
      // Release focus lock
      await _controller!.setFocusMode(FocusMode.auto);

      // Perform quality checks
      final quality = CaptureQuality(
        isBlurry: false, // Will be checked by ML service
        lightingQuality: LightingQuality.good,
        hasFlash: _controller!.value.flashMode != FlashMode.off,
      );

      return CaptureResult(
        imagePath: image.path,
        quality: quality,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ Image capture failed: $e');
      rethrow;
    }
  }

  /// Analyze current frame lighting (simplified - in real app use ML)
  Future<LightingQuality> analyzeLighting() async {
    if (!isReady) return LightingQuality.unknown;
    
    // In production, this would analyze the camera stream
    // For now, return a placeholder
    // You would use image analysis or ML here
    return LightingQuality.good;
  }

  /// Enable/disable flash
  Future<void> setFlashMode(FlashMode mode) async {
    if (!isReady) return;
    await _controller!.setFlashMode(mode);
  }

  /// Switch between front/back camera
  Future<void> switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;

    final currentDirection = _controller!.description.lensDirection;
    final newDirection = currentDirection == CameraLensDirection.back
        ? CameraLensDirection.front
        : CameraLensDirection.back;

    await dispose();
    await initialize(direction: newDirection);
  }

  /// Set zoom level (0.0 to 1.0)
  Future<void> setZoom(double zoom) async {
    if (!isReady) return;
    
    final maxZoom = await _controller!.getMaxZoomLevel();
    final minZoom = await _controller!.getMinZoomLevel();
    
    final targetZoom = minZoom + (zoom * (maxZoom - minZoom));
    await _controller!.setZoomLevel(targetZoom.clamp(minZoom, maxZoom));
  }

  /// Focus on a specific point (0.0 to 1.0 for x and y)
  Future<void> focusOnPoint(double x, double y) async {
    if (!isReady) return;
    
    try {
      await _controller!.setFocusPoint(Offset(x, y));
      await _controller!.setFocusMode(FocusMode.auto);
    } catch (e) {
      debugPrint('Focus on point failed: $e');
    }
  }

  /// Enable exposure compensation (-1.0 to 1.0)
  Future<void> setExposure(double exposure) async {
    if (!isReady) return;
    
    final maxExposure = await _controller!.getMaxExposureOffset();
    final minExposure = await _controller!.getMinExposureOffset();
    
    final targetExposure = exposure.clamp(minExposure, maxExposure);
    await _controller!.setExposureOffset(targetExposure);
  }

  /// Dispose camera resources
  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
    _isInitialized = false;
  }
}

/// Result of image capture with quality metrics
class CaptureResult {
  final String imagePath;
  final CaptureQuality quality;
  final DateTime timestamp;

  CaptureResult({
    required this.imagePath,
    required this.quality,
    required this.timestamp,
  });

  bool get isAcceptableQuality =>
      !quality.isBlurry && quality.lightingQuality != LightingQuality.poor;
}

/// Quality assessment of captured image
class CaptureQuality {
  final bool isBlurry;
  final LightingQuality lightingQuality;
  final bool hasFlash;

  CaptureQuality({
    required this.isBlurry,
    required this.lightingQuality,
    required this.hasFlash,
  });

  int get score {
    int points = 0;
    if (!isBlurry) points += 50;
    
    switch (lightingQuality) {
      case LightingQuality.excellent:
        points += 50;
        break;
      case LightingQuality.good:
        points += 40;
        break;
      case LightingQuality.fair:
        points += 25;
        break;
      case LightingQuality.poor:
        points += 0;
        break;
      case LightingQuality.unknown:
        points += 20;
        break;
    }
    
    return points;
  }

  String get description {
    if (score >= 90) return 'Excellent';
    if (score >= 75) return 'Good';
    if (score >= 50) return 'Fair';
    return 'Poor - Retake recommended';
  }
}

enum LightingQuality {
  excellent,
  good,
  fair,
  poor,
  unknown,
}
