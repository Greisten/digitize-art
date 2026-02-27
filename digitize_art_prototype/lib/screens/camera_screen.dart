import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import '../services/camera_service.dart';
import '../services/edge_detection_service.dart';
import '../widgets/ar_overlay.dart';
import '../widgets/capture_button.dart';
import 'settings_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  bool _isDetecting = false;
  EdgeDetectionResult? _lastDetection;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameraService = context.read<CameraService>();
    await cameraService.initialize();
    
    // Start continuous edge detection
    _startEdgeDetection();
  }

  void _startEdgeDetection() {
    final cameraService = context.read<CameraService>();
    final edgeService = context.read<EdgeDetectionService>();
    
    if (cameraService.controller == null) return;

    // Process frames at ~10 FPS to avoid overwhelming the CPU
    cameraService.controller!.startImageStream((CameraImage image) async {
      if (_isDetecting) return;
      
      _isDetecting = true;
      
      try {
        final result = await edgeService.detectEdges(image);
        
        if (mounted) {
          setState(() {
            _lastDetection = result;
          });
        }
      } catch (e) {
        debugPrint('Edge detection error: $e');
      } finally {
        await Future.delayed(const Duration(milliseconds: 100));
        _isDetecting = false;
      }
    });
  }

  void _stopEdgeDetection() {
    final cameraService = context.read<CameraService>();
    cameraService.controller?.stopImageStream();
  }

  Future<void> _captureImage() async {
    final cameraService = context.read<CameraService>();
    
    if (cameraService.controller == null || !cameraService.isInitialized) {
      return;
    }

    try {
      // Stop detection during capture
      _stopEdgeDetection();
      
      final image = await cameraService.controller!.takePicture();
      
      if (mounted) {
        // Show success feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image captured: ${image.path}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
      // Resume detection
      _startEdgeDetection();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Capture failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _stopEdgeDetection();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<CameraService>(
        builder: (context, cameraService, child) {
          if (cameraService.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    cameraService.error!,
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => cameraService.initialize(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!cameraService.isInitialized) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final controller = cameraService.controller!;

          return Stack(
            fit: StackFit.expand,
            children: [
              // Camera preview
              Center(
                child: AspectRatio(
                  aspectRatio: controller.value.aspectRatio,
                  child: CameraPreview(controller),
                ),
              ),

              // AR Overlay
              AROverlay(
                detection: _lastDetection,
              ),

              // Top controls
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Detection status
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _lastDetection?.hasDetection ?? false
                                  ? Icons.check_circle
                                  : Icons.search,
                              color: _lastDetection?.hasDetection ?? false
                                  ? Colors.green
                                  : Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _lastDetection?.hasDetection ?? false
                                  ? 'Artwork detected'
                                  : 'Scanning...',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Camera switch
                    if (cameraService.cameras.length > 1)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: IconButton(
                          onPressed: () => cameraService.switchCamera(),
                          icon: const Icon(
                            Icons.flip_camera_ios,
                            color: Colors.white,
                          ),
                        ),
                      ),

                    const SizedBox(width: 8),

                    // Settings button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const SettingsScreen(),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.menu,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom controls
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 32,
                left: 0,
                right: 0,
                child: CaptureButton(
                  onPressed: _captureImage,
                  isEnabled: _lastDetection?.hasDetection ?? false,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
