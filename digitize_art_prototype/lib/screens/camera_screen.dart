import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:provider/provider.dart';
import '../services/camera_service.dart';
import '../services/edge_detection_service.dart';
import '../services/hdr_capture_service.dart';
import '../services/lighting_analysis_service.dart';
import '../widgets/ar_overlay.dart';
import '../widgets/capture_button.dart';
import '../widgets/lighting_guidance_overlay.dart';
import '../theme/app_theme.dart';
import 'gallery_screen.dart';
import 'review_screen.dart';
import 'settings_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  bool _isDetecting = false;
  EdgeDetectionResult? _lastDetection;
  LightingAnalysisResult? _lastLightingAnalysis;

  bool _hdrMode = false;
  bool _isCapturing = false;
  final HdrCaptureService _hdrService = HdrCaptureService();

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
    final lightingService = LightingAnalysisService();
    
    final controller = cameraService.controller;
    if (controller == null) return;
    // Avoid starting a second stream if one is already running.
    if (controller.value.isStreamingImages) return;

    final sensorOrientation = controller.description.sensorOrientation;

    // Process frames at ~5 FPS to avoid overwhelming the CPU
    // (slower because we're running two analyses now)
    controller.startImageStream((CameraImage image) async {
      if (_isDetecting) return;

      _isDetecting = true;

      try {
        // Run both analyses in parallel
        final results = await Future.wait([
          edgeService.detectEdges(image, sensorOrientation: sensorOrientation),
          lightingService.analyze(image),
        ]);
        
        if (mounted) {
          setState(() {
            _lastDetection = results[0] as EdgeDetectionResult;
            _lastLightingAnalysis = results[1] as LightingAnalysisResult;
          });
        }
      } catch (e) {
        debugPrint('Analysis error: $e');
      } finally {
        await Future.delayed(const Duration(milliseconds: 200));
        _isDetecting = false;
      }
    });
  }

  void _stopEdgeDetection() {
    final cameraService = context.read<CameraService>();
    final controller = cameraService.controller;
    // Only stop if a stream is actually running, otherwise the plugin throws.
    if (controller != null && controller.value.isStreamingImages) {
      controller.stopImageStream();
    }
  }

  Future<void> _onCapturePressed() async {
    if (_isCapturing) return;
    if (_hdrMode) {
      await _captureHdr();
    } else {
      await _captureImage();
    }
  }

  /// Push the review screen for a freshly captured image, then surface a
  /// confirmation if the user saved it.
  Future<void> _openReview(String path, {required bool isHdr}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ReviewScreen(imagePath: path, isHdr: isHdr),
      ),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Scan enregistré'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _openGallery() async {
    _stopEdgeDetection();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const GalleryScreen()),
    );
    if (mounted) _startEdgeDetection();
  }

  /// Launch the native AI document scanner (VisionKit on iOS / ML Kit on
  /// Android): automatic edge detection + perspective crop. The cropped result
  /// is routed to the review screen like a normal capture.
  Future<void> _scanWithAI() async {
    if (_isCapturing) return;
    setState(() => _isCapturing = true);
    // Release our camera session before the native scanner takes over.
    _stopEdgeDetection();

    String? path;
    try {
      final pictures =
          await CunningDocumentScanner.getPictures(noOfPages: 1);
      if (pictures != null && pictures.isNotEmpty) {
        path = pictures.first;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Scan IA indisponible : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }

    if (mounted && path != null) {
      await _openReview(path, isHdr: false);
    }
    if (mounted) _startEdgeDetection();
  }

  Future<void> _captureHdr() async {
    final cameraService = context.read<CameraService>();
    final controller = cameraService.controller;

    if (controller == null || !cameraService.isInitialized) {
      return;
    }

    setState(() => _isCapturing = true);
    // Stop the live analysis stream while we take the bracketed shots.
    _stopEdgeDetection();

    String? path;
    bool isHdr = false;
    try {
      final result = await _hdrService.captureHdr(controller);
      path = result.path;
      isHdr = result.fused;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Échec capture HDR : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }

    if (mounted && path != null) {
      await _openReview(path, isHdr: isHdr);
    }
    if (mounted) _startEdgeDetection();
  }

  Future<void> _captureImage() async {
    final cameraService = context.read<CameraService>();
    final controller = cameraService.controller;

    if (controller == null || !cameraService.isInitialized) {
      return;
    }

    setState(() => _isCapturing = true);
    // Stop detection during capture.
    _stopEdgeDetection();

    String? path;
    try {
      final image = await controller.takePicture();
      path = image.path;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Échec de la capture : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }

    if (mounted && path != null) {
      await _openReview(path, isHdr: false);
    }
    if (mounted) _startEdgeDetection();
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
                    child: const Text('Réessayer'),
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
              // Camera preview (fullscreen, no distortion).
              // previewSize is in the sensor's landscape orientation, so we
              // swap width/height for the portrait view and cover-fit it.
              Positioned.fill(
                child: ClipRect(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: controller.value.previewSize?.height ??
                          MediaQuery.of(context).size.width,
                      height: controller.value.previewSize?.width ??
                          MediaQuery.of(context).size.height,
                      child: CameraPreview(controller),
                    ),
                  ),
                ),
              ),

              // AR Overlay
              AROverlay(
                detection: _lastDetection,
              ),

              // Lighting Guidance Overlay
              LightingGuidanceOverlay(
                analysis: _lastLightingAnalysis,
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
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _lastDetection?.hasDetection ?? false
                                        ? 'Œuvre détectée'
                                        : 'Recherche…',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (_lastLightingAnalysis != null)
                                    Text(
                                      '${(_lastLightingAnalysis!.colorTemperature).round()}K • ${(_lastLightingAnalysis!.overallScore * 100).round()}% qualité',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                      ),
                                    ),
                                ],
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

                    // HDR multi-shot toggle
                    Container(
                      decoration: BoxDecoration(
                        color: _hdrMode
                            ? AppTheme.secondaryMain.withOpacity(0.9)
                            : Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        tooltip: 'HDR multi-shot',
                        onPressed: _isCapturing
                            ? null
                            : () => setState(() => _hdrMode = !_hdrMode),
                        icon: const Icon(
                          Icons.hdr_on,
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
                  onPressed: _onCapturePressed,
                  isEnabled: !_isCapturing &&
                      (_lastDetection?.hasDetection ?? false) &&
                      (_lastLightingAnalysis?.overallScore ?? 0) >= 0.4,
                ),
              ),

              // Gallery shortcut (bottom-left)
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 40,
                left: 24,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: IconButton(
                    tooltip: 'Mes scans',
                    onPressed: _isCapturing ? null : _openGallery,
                    icon: const Icon(
                      Icons.photo_library_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),

              // AI auto-scan (VisionKit) — bottom-right
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 40,
                right: 24,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primaryMain,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: IconButton(
                        tooltip: 'Scan auto (IA)',
                        onPressed: _isCapturing ? null : _scanWithAI,
                        icon: const Icon(
                          Icons.document_scanner_outlined,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'IA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              // Capture progress overlay
              if (_isCapturing)
                Positioned.fill(
                  child: Container(
                    color: Colors.black54,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: Colors.white),
                          const SizedBox(height: 16),
                          Text(
                            _hdrMode
                                ? 'Capture HDR (3 expositions)…'
                                : 'Capture…',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
