// lib/shared/services/image_processing_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Service for image processing operations
class ImageProcessingService {
  /// Detect edges in image and find artwork boundaries
  /// Returns list of corner points [topLeft, topRight, bottomRight, bottomLeft]
  Future<List<Point>?> detectEdges(String imagePath) async {
    return compute(_detectEdgesIsolate, imagePath);
  }

  static Future<List<Point>?> _detectEdgesIsolate(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) return null;

      // Convert to grayscale
      final gray = img.grayscale(image);
      
      // Apply Gaussian blur to reduce noise
      final blurred = img.gaussianBlur(gray, radius: 5);
      
      // Edge detection using Sobel filter
      final edges = img.sobel(blurred);
      
      // Find contours (simplified - in production use OpenCV)
      // This is a placeholder - you'll need OpenCV bindings for proper edge detection
      final corners = _findLargestQuadrilateral(edges);
      
      return corners;
    } catch (e) {
      debugPrint('Edge detection failed: $e');
      return null;
    }
  }

  /// Find the largest quadrilateral in the edge-detected image
  static List<Point>? _findLargestQuadrilateral(img.Image edges) {
    // Simplified corner detection
    // In production, use OpenCV's findContours and approxPolyDP
    
    final width = edges.width;
    final height = edges.height;
    
    // Default to full image corners with small inset
    final inset = 20;
    return [
      Point(inset.toDouble(), inset.toDouble()), // top-left
      Point(width - inset.toDouble(), inset.toDouble()), // top-right
      Point(width - inset.toDouble(), height - inset.toDouble()), // bottom-right
      Point(inset.toDouble(), height - inset.toDouble()), // bottom-left
    ];
  }

  /// Correct perspective distortion based on detected corners
  Future<String> correctPerspective(
    String imagePath,
    List<Point> corners,
  ) async {
    return compute(
      _correctPerspectiveIsolate,
      PerspectiveParams(imagePath, corners),
    );
  }

  static Future<String> _correctPerspectiveIsolate(
    PerspectiveParams params,
  ) async {
    try {
      final bytes = await File(params.imagePath).readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) throw Exception('Failed to decode image');

      // Calculate target dimensions
      final width = _distance(params.corners[0], params.corners[1]).round();
      final height = _distance(params.corners[0], params.corners[3]).round();

      // Create perspective transform matrix
      // In production, use OpenCV's getPerspectiveTransform and warpPerspective
      
      // For now, we'll do a simple crop to the detected region
      final cropped = _cropToQuad(image, params.corners);
      
      // Resize to target dimensions
      final corrected = img.copyResize(
        cropped,
        width: width,
        height: height,
        interpolation: img.Interpolation.cubic,
      );

      // Save processed image
      final tempDir = await getTemporaryDirectory();
      final outputPath = path.join(
        tempDir.path,
        'processed_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      
      await File(outputPath).writeAsBytes(
        img.encodeJpg(corrected, quality: 95),
      );

      return outputPath;
    } catch (e) {
      debugPrint('Perspective correction failed: $e');
      rethrow;
    }
  }

  static img.Image _cropToQuad(img.Image image, List<Point> corners) {
    // Find bounding box
    final minX = corners.map((p) => p.x).reduce((a, b) => a < b ? a : b).round();
    final maxX = corners.map((p) => p.x).reduce((a, b) => a > b ? a : b).round();
    final minY = corners.map((p) => p.y).reduce((a, b) => a < b ? a : b).round();
    final maxY = corners.map((p) => p.y).reduce((a, b) => a > b ? a : b).round();
    
    return img.copyCrop(
      image,
      x: minX,
      y: minY,
      width: maxX - minX,
      height: maxY - minY,
    );
  }

  static double _distance(Point a, Point b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    return (dx * dx + dy * dy).sqrt();
  }

  /// Enhance image quality (brightness, contrast, sharpness)
  Future<String> enhanceImage(
    String imagePath, {
    double brightness = 1.0,
    double contrast = 1.0,
    double saturation = 1.0,
    int sharpness = 0,
  }) async {
    return compute(
      _enhanceImageIsolate,
      EnhanceParams(
        imagePath,
        brightness,
        contrast,
        saturation,
        sharpness,
      ),
    );
  }

  static Future<String> _enhanceImageIsolate(EnhanceParams params) async {
    try {
      final bytes = await File(params.imagePath).readAsBytes();
      var image = img.decodeImage(bytes);
      
      if (image == null) throw Exception('Failed to decode image');

      // Adjust brightness (-1.0 to 1.0, mapped to 0.0 to 2.0)
      if (params.brightness != 1.0) {
        final brightnessFactor = (params.brightness - 1.0) * 100;
        image = img.adjustColor(
          image,
          brightness: brightnessFactor,
        );
      }

      // Adjust contrast
      if (params.contrast != 1.0) {
        final contrastFactor = (params.contrast - 1.0) * 100;
        image = img.adjustColor(
          image,
          contrast: contrastFactor,
        );
      }

      // Adjust saturation
      if (params.saturation != 1.0) {
        final saturationFactor = (params.saturation - 1.0) * 100;
        image = img.adjustColor(
          image,
          saturation: saturationFactor,
        );
      }

      // Apply sharpening
      if (params.sharpness > 0) {
        image = img.convolution(
          image,
          filter: _getSharpenKernel(params.sharpness),
        );
      }

      // Save enhanced image
      final tempDir = await getTemporaryDirectory();
      final outputPath = path.join(
        tempDir.path,
        'enhanced_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      
      await File(outputPath).writeAsBytes(
        img.encodeJpg(image, quality: 95),
      );

      return outputPath;
    } catch (e) {
      debugPrint('Image enhancement failed: $e');
      rethrow;
    }
  }

  static List<num> _getSharpenKernel(int strength) {
    final s = strength / 10.0;
    return [
      0, -s, 0,
      -s, 1 + 4 * s, -s,
      0, -s, 0,
    ];
  }

  /// Remove noise from image
  Future<String> removeNoise(String imagePath, {int radius = 3}) async {
    return compute(_removeNoiseIsolate, NoiseParams(imagePath, radius));
  }

  static Future<String> _removeNoiseIsolate(NoiseParams params) async {
    try {
      final bytes = await File(params.imagePath).readAsBytes();
      var image = img.decodeImage(bytes);
      
      if (image == null) throw Exception('Failed to decode image');

      // Apply bilateral filter for noise reduction while preserving edges
      // Using Gaussian blur as approximation
      image = img.gaussianBlur(image, radius: params.radius);

      final tempDir = await getTemporaryDirectory();
      final outputPath = path.join(
        tempDir.path,
        'denoised_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      
      await File(outputPath).writeAsBytes(
        img.encodeJpg(image, quality: 95),
      );

      return outputPath;
    } catch (e) {
      debugPrint('Noise removal failed: $e');
      rethrow;
    }
  }

  /// Auto white balance correction
  Future<String> correctWhiteBalance(String imagePath) async {
    return compute(_correctWhiteBalanceIsolate, imagePath);
  }

  static Future<String> _correctWhiteBalanceIsolate(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      var image = img.decodeImage(bytes);
      
      if (image == null) throw Exception('Failed to decode image');

      // Simple gray world assumption for white balance
      image = img.normalize(image, min: 0, max: 255);

      final tempDir = await getTemporaryDirectory();
      final outputPath = path.join(
        tempDir.path,
        'wb_corrected_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      
      await File(outputPath).writeAsBytes(
        img.encodeJpg(image, quality: 95),
      );

      return outputPath;
    } catch (e) {
      debugPrint('White balance correction failed: $e');
      rethrow;
    }
  }

  /// Detect blur in image (returns laplacian variance)
  Future<double> detectBlur(String imagePath) async {
    return compute(_detectBlurIsolate, imagePath);
  }

  static Future<double> _detectBlurIsolate(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) return 0.0;

      // Convert to grayscale
      final gray = img.grayscale(image);
      
      // Apply Laplacian filter
      final laplacian = img.convolution(
        gray,
        filter: [
          0, 1, 0,
          1, -4, 1,
          0, 1, 0,
        ],
      );

      // Calculate variance
      double sum = 0.0;
      double sumSquared = 0.0;
      int count = 0;

      for (int y = 0; y < laplacian.height; y++) {
        for (int x = 0; x < laplacian.width; x++) {
          final pixel = laplacian.getPixel(x, y);
          final value = pixel.r.toDouble();
          sum += value;
          sumSquared += value * value;
          count++;
        }
      }

      final mean = sum / count;
      final variance = (sumSquared / count) - (mean * mean);

      return variance;
    } catch (e) {
      debugPrint('Blur detection failed: $e');
      return 0.0;
    }
  }
}

class Point {
  final double x;
  final double y;

  Point(this.x, this.y);
  
  @override
  String toString() => '($x, $y)';
}

class PerspectiveParams {
  final String imagePath;
  final List<Point> corners;

  PerspectiveParams(this.imagePath, this.corners);
}

class EnhanceParams {
  final String imagePath;
  final double brightness;
  final double contrast;
  final double saturation;
  final int sharpness;

  EnhanceParams(
    this.imagePath,
    this.brightness,
    this.contrast,
    this.saturation,
    this.sharpness,
  );
}

class NoiseParams {
  final String imagePath;
  final int radius;

  NoiseParams(this.imagePath, this.radius);
}
