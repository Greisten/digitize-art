// lib/shared/services/ml_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

/// Machine Learning service for AI-powered features
class MLService {
  Interpreter? _edgeDetectionInterpreter;
  Interpreter? _enhancementInterpreter;
  Interpreter? _blurDetectionInterpreter;

  bool _isInitialized = false;

  /// Initialize ML models
  Future<void> initialize() async {
    try {
      // Load edge detection model
      _edgeDetectionInterpreter = await Interpreter.fromAsset(
        'assets/ml_models/edge_detection.tflite',
      );

      // Load enhancement model (premium feature)
      _enhancementInterpreter = await Interpreter.fromAsset(
        'assets/ml_models/image_enhancement.tflite',
      );

      // Load blur detection model
      _blurDetectionInterpreter = await Interpreter.fromAsset(
        'assets/ml_models/blur_detection.tflite',
      );

      _isInitialized = true;
      debugPrint('✅ ML models loaded successfully');
    } catch (e) {
      debugPrint('❌ Failed to load ML models: $e');
      rethrow;
    }
  }

  /// Detect artwork edges using ML
  /// Returns confidence score and corner points
  Future<EdgeDetectionResult> detectArtworkEdges(String imagePath) async {
    if (!_isInitialized) {
      throw Exception('ML Service not initialized');
    }

    try {
      // Load and preprocess image
      final inputImage = await _preprocessImage(
        imagePath,
        targetSize: 256, // Model expects 256x256 input
      );

      // Prepare output buffer
      // Output: [1, 256, 256, 1] (heatmap of edge probabilities)
      final output = List.generate(
        1,
        (_) => List.generate(
          256,
          (_) => List.generate(256, (_) => List.filled(1, 0.0)),
        ),
      );

      // Run inference
      _edgeDetectionInterpreter!.run(inputImage, output);

      // Post-process output to extract corner points
      final corners = _extractCorners(output[0]);
      final confidence = _calculateConfidence(output[0]);

      return EdgeDetectionResult(
        corners: corners,
        confidence: confidence,
        isReliable: confidence > 0.75,
      );
    } catch (e) {
      debugPrint('Edge detection failed: $e');
      rethrow;
    }
  }

  /// Enhance image quality using AI (Premium feature)
  Future<Uint8List> enhanceImageQuality(String imagePath) async {
    if (!_isInitialized) {
      throw Exception('ML Service not initialized');
    }

    try {
      // Load image
      final bytes = await File(imagePath).readAsBytes();
      final image = img.decodeImage(bytes)!;

      // Process in tiles for large images
      final enhanced = await _enhanceInTiles(image);

      // Encode back to bytes
      return Uint8List.fromList(img.encodeJpg(enhanced, quality: 95));
    } catch (e) {
      debugPrint('Image enhancement failed: $e');
      rethrow;
    }
  }

  /// Detect blur in image
  /// Returns blur score (0.0 = sharp, 1.0 = very blurry)
  Future<double> detectBlur(String imagePath) async {
    if (!_isInitialized) {
      throw Exception('ML Service not initialized');
    }

    try {
      final inputImage = await _preprocessImage(imagePath, targetSize: 224);

      // Output: [1, 1] (blur probability)
      final output = List.filled(1, 0.0).reshape([1, 1]);

      _blurDetectionInterpreter!.run(inputImage, output);

      return output[0][0];
    } catch (e) {
      debugPrint('Blur detection failed: $e');
      return 0.0;
    }
  }

  /// Preprocess image for model input
  Future<List<List<List<List<double>>>>> _preprocessImage(
    String imagePath, {
    required int targetSize,
  }) async {
    final bytes = await File(imagePath).readAsBytes();
    var image = img.decodeImage(bytes)!;

    // Resize to model input size
    image = img.copyResize(
      image,
      width: targetSize,
      height: targetSize,
      interpolation: img.Interpolation.cubic,
    );

    // Convert to normalized float array [0, 1]
    final input = List.generate(
      1,
      (_) => List.generate(
        targetSize,
        (y) => List.generate(
          targetSize,
          (x) {
            final pixel = image.getPixel(x, y);
            // Convert RGB to float and normalize
            return [
              pixel.r / 255.0,
              pixel.g / 255.0,
              pixel.b / 255.0,
            ];
          },
        ),
      ),
    );

    return input;
  }

  /// Extract corner points from edge heatmap
  List<Point> _extractCorners(List<List<List<double>>> heatmap) {
    // Simplified corner extraction
    // In production, use more sophisticated peak detection
    
    final size = heatmap.length;
    final peaks = <Point>[];

    // Find local maxima
    for (int y = 1; y < size - 1; y++) {
      for (int x = 1; x < size - 1; x++) {
        final value = heatmap[y][x][0];
        
        if (value > 0.7 && _isLocalMaxima(heatmap, x, y)) {
          peaks.add(Point(x.toDouble(), y.toDouble()));
        }
      }
    }

    // Select 4 corners (simplified - use convex hull in production)
    if (peaks.length >= 4) {
      return _selectBestFourCorners(peaks);
    }

    // Fallback to image corners
    return [
      Point(10, 10),
      Point(size - 10.0, 10),
      Point(size - 10.0, size - 10.0),
      Point(10, size - 10.0),
    ];
  }

  bool _isLocalMaxima(List<List<List<double>>> heatmap, int x, int y) {
    final value = heatmap[y][x][0];
    
    for (int dy = -1; dy <= 1; dy++) {
      for (int dx = -1; dx <= 1; dx++) {
        if (dx == 0 && dy == 0) continue;
        if (heatmap[y + dy][x + dx][0] > value) return false;
      }
    }
    
    return true;
  }

  List<Point> _selectBestFourCorners(List<Point> peaks) {
    // Sort by distance from center
    peaks.sort((a, b) {
      final distA = (a.x - 128).abs() + (a.y - 128).abs();
      final distB = (b.x - 128).abs() + (b.y - 128).abs();
      return distB.compareTo(distA);
    });

    // Take the 4 points furthest from center (likely corners)
    return peaks.take(4).toList();
  }

  double _calculateConfidence(List<List<List<double>>> heatmap) {
    // Calculate average confidence of detected edges
    double sum = 0.0;
    int count = 0;

    for (final row in heatmap) {
      for (final pixel in row) {
        if (pixel[0] > 0.5) {
          sum += pixel[0];
          count++;
        }
      }
    }

    return count > 0 ? sum / count : 0.0;
  }

  /// Enhance image in tiles to handle large images
  Future<img.Image> _enhanceInTiles(img.Image image) async {
    const tileSize = 512;
    final width = image.width;
    final height = image.height;

    final result = img.Image(width: width, height: height);

    for (int y = 0; y < height; y += tileSize) {
      for (int x = 0; x < width; x += tileSize) {
        final tileWidth = (x + tileSize > width) ? width - x : tileSize;
        final tileHeight = (y + tileSize > height) ? height - y : tileSize;

        // Extract tile
        final tile = img.copyCrop(
          image,
          x: x,
          y: y,
          width: tileWidth,
          height: tileHeight,
        );

        // Enhance tile
        final enhancedTile = await _enhanceTile(tile);

        // Copy back to result
        img.compositeImage(result, enhancedTile, dstX: x, dstY: y);
      }
    }

    return result;
  }

  Future<img.Image> _enhanceTile(img.Image tile) async {
    // Resize to model input size
    final resized = img.copyResize(
      tile,
      width: 512,
      height: 512,
    );

    // Prepare input
    final input = _imageToFloatArray(resized);

    // Prepare output
    final output = List.generate(
      1,
      (_) => List.generate(
        512,
        (_) => List.generate(512, (_) => List.filled(3, 0.0)),
      ),
    );

    // Run inference
    _enhancementInterpreter!.run(input, output);

    // Convert output back to image
    final enhanced = _floatArrayToImage(output[0]);

    // Resize back to original tile size
    return img.copyResize(
      enhanced,
      width: tile.width,
      height: tile.height,
    );
  }

  List<List<List<List<double>>>> _imageToFloatArray(img.Image image) {
    return List.generate(
      1,
      (_) => List.generate(
        image.height,
        (y) => List.generate(
          image.width,
          (x) {
            final pixel = image.getPixel(x, y);
            return [
              pixel.r / 255.0,
              pixel.g / 255.0,
              pixel.b / 255.0,
            ];
          },
        ),
      ),
    );
  }

  img.Image _floatArrayToImage(List<List<List<double>>> array) {
    final height = array.length;
    final width = array[0].length;
    final image = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final r = (array[y][x][0] * 255).clamp(0, 255).toInt();
        final g = (array[y][x][1] * 255).clamp(0, 255).toInt();
        final b = (array[y][x][2] * 255).clamp(0, 255).toInt();
        
        image.setPixelRgba(x, y, r, g, b, 255);
      }
    }

    return image;
  }

  /// Dispose of ML resources
  void dispose() {
    _edgeDetectionInterpreter?.close();
    _enhancementInterpreter?.close();
    _blurDetectionInterpreter?.close();
    _isInitialized = false;
  }
}

class Point {
  final double x;
  final double y;

  Point(this.x, this.y);

  @override
  String toString() => '($x, $y)';
}

class EdgeDetectionResult {
  final List<Point> corners;
  final double confidence;
  final bool isReliable;

  EdgeDetectionResult({
    required this.corners,
    required this.confidence,
    required this.isReliable,
  });

  @override
  String toString() =>
      'EdgeDetectionResult(corners: $corners, confidence: $confidence, reliable: $isReliable)';
}

// Extension for reshaping lists (helper)
extension ListReshape on List {
  List reshape(List<int> shape) {
    // Simplified reshape - just for output buffer
    return this;
  }
}
