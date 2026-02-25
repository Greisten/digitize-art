// lib/features/capture/presentation/screens/camera_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';

/// Main camera screen for capturing artwork
class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isInitializing = true;
  bool _flashEnabled = false;
  bool _arGuidanceEnabled = true;
  List<Offset>? _detectedCorners;
  String _statusMessage = 'Initializing camera...';
  LightingStatus _lightingStatus = LightingStatus.unknown;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        camera,
        ResolutionPreset.veryHigh,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      await _controller!.setFlashMode(FlashMode.off);
      await _controller!.setFocusMode(FocusMode.auto);

      if (mounted) {
        setState(() {
          _isInitializing = false;
          _statusMessage = 'Ready to scan';
        });
        
        // Start edge detection loop
        _startEdgeDetection();
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _statusMessage = 'Camera error';
        });
      }
    }
  }

  void _startEdgeDetection() {
    // Simulate real-time edge detection
    // In production, this would process camera frames
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _arGuidanceEnabled) {
        setState(() {
          // Simulate detected corners (in production, use ML)
          final size = MediaQuery.of(context).size;
          _detectedCorners = [
            Offset(size.width * 0.1, size.height * 0.2),
            Offset(size.width * 0.9, size.height * 0.2),
            Offset(size.width * 0.9, size.height * 0.7),
            Offset(size.width * 0.1, size.height * 0.7),
          ];
          _lightingStatus = LightingStatus.good;
          _statusMessage = 'Artwork detected - Ready to capture';
        });
      }
    });
  }

  Future<void> _captureImage() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    try {
      // Lock focus
      await _controller!.setFocusMode(FocusMode.locked);
      await Future.delayed(const Duration(milliseconds: 200));

      // Capture
      final image = await _controller!.takePicture();

      // Haptic feedback
      // HapticFeedback.mediumImpact();

      // Navigate to preview
      if (mounted) {
        Navigator.of(context).pushNamed(
          '/preview',
          arguments: {
            'imagePath': image.path,
            'detectedCorners': _detectedCorners,
          },
        );
      }

      // Reset focus
      await _controller!.setFocusMode(FocusMode.auto);
    } catch (e) {
      debugPrint('Capture error: $e');
      _showError('Failed to capture image');
    }
  }

  Future<void> _toggleFlash() async {
    if (_controller == null) return;

    setState(() {
      _flashEnabled = !_flashEnabled;
    });

    await _controller!.setFlashMode(
      _flashEnabled ? FlashMode.torch : FlashMode.off,
    );
  }

  void _toggleARGuidance() {
    setState(() {
      _arGuidanceEnabled = !_arGuidanceEnabled;
      if (!_arGuidanceEnabled) {
        _detectedCorners = null;
      } else {
        _startEdgeDetection();
      }
    });
  }

  Future<void> _switchCamera() async {
    if (_controller == null) return;

    final lensDirection = _controller!.description.lensDirection;
    final cameras = await availableCameras();
    
    final newCamera = cameras.firstWhere(
      (c) => c.lensDirection != lensDirection,
      orElse: () => cameras.first,
    );

    await _controller!.dispose();
    
    _controller = CameraController(
      newCamera,
      ResolutionPreset.veryHigh,
      enableAudio: false,
    );

    await _controller!.initialize();
    setState(() {});
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 64),
              const SizedBox(height: 16),
              Text(
                _statusMessage,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _initializeCamera,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview
          Center(
            child: CameraPreview(_controller!),
          ),

          // AR Guidance overlay
          if (_arGuidanceEnabled && _detectedCorners != null)
            CustomPaint(
              painter: EdgeDetectionPainter(_detectedCorners!),
              size: Size.infinite,
            ),

          // Top controls
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Top bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              _flashEnabled ? Icons.flash_on : Icons.flash_off,
                              color: Colors.white,
                            ),
                            onPressed: _toggleFlash,
                          ),
                          IconButton(
                            icon: const Icon(Icons.settings, color: Colors.white),
                            onPressed: () {
                              // Open settings
                            },
                          ),
                        ],
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Status indicators
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getLightingIcon(),
                              color: _getLightingColor(),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Lighting: ${_lightingStatus.name}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _statusMessage,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Gallery
                    IconButton(
                      icon: const Icon(Icons.photo_library, color: Colors.white, size: 32),
                      onPressed: () {
                        // Open gallery
                      },
                    ),

                    // Capture button
                    GestureDetector(
                      onTap: _captureImage,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Flip camera
                    IconButton(
                      icon: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 32),
                      onPressed: _switchCamera,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getLightingIcon() {
    switch (_lightingStatus) {
      case LightingStatus.excellent:
      case LightingStatus.good:
        return Icons.wb_sunny;
      case LightingStatus.fair:
        return Icons.wb_cloudy;
      case LightingStatus.poor:
        return Icons.warning;
      case LightingStatus.unknown:
        return Icons.help_outline;
    }
  }

  Color _getLightingColor() {
    switch (_lightingStatus) {
      case LightingStatus.excellent:
      case LightingStatus.good:
        return Colors.green;
      case LightingStatus.fair:
        return Colors.orange;
      case LightingStatus.poor:
        return Colors.red;
      case LightingStatus.unknown:
        return Colors.grey;
    }
  }
}

enum LightingStatus {
  excellent,
  good,
  fair,
  poor,
  unknown,
}

/// Custom painter for edge detection overlay
class EdgeDetectionPainter extends CustomPainter {
  final List<Offset> corners;

  EdgeDetectionPainter(this.corners);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green.withOpacity(0.7)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(corners[0].dx, corners[0].dy)
      ..lineTo(corners[1].dx, corners[1].dy)
      ..lineTo(corners[2].dx, corners[2].dy)
      ..lineTo(corners[3].dx, corners[3].dy)
      ..close();

    canvas.drawPath(path, paint);

    // Draw corner circles
    final circlePaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;

    for (final corner in corners) {
      canvas.drawCircle(corner, 8, circlePaint);
    }
  }

  @override
  bool shouldRepaint(EdgeDetectionPainter oldDelegate) {
    return corners != oldDelegate.corners;
  }
}
