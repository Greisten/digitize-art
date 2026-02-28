import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'dart:math' as math;

class LightingAnalysisService {
  /// Analyze camera frame for lighting quality, positioning, and issues
  Future<LightingAnalysisResult> analyze(CameraImage image) async {
    try {
      final rgbImage = _convertYUV420ToImage(image);
      if (rgbImage == null) {
        return LightingAnalysisResult.empty();
      }

      // Run all analyses
      final exposure = _analyzeExposure(rgbImage);
      final colorTemp = _analyzeColorTemperature(rgbImage);
      final position = _analyzePosition(rgbImage);
      final blur = _detectMotionBlur(rgbImage);
      final glare = _detectGlare(rgbImage);
      final shadows = _detectShadows(rgbImage);

      return LightingAnalysisResult(
        exposureLevel: exposure.level,
        exposureScore: exposure.score,
        colorTemperature: colorTemp.kelvin,
        colorTempScore: colorTemp.score,
        positionHorizontal: position.horizontal,
        positionVertical: position.vertical,
        positionScore: position.score,
        hasMotionBlur: blur.detected,
        blurIntensity: blur.intensity,
        hasGlare: glare.detected,
        glareIntensity: glare.intensity,
        hasShadows: shadows.detected,
        shadowIntensity: shadows.intensity,
        overallScore: _calculateOverallScore(
          exposure.score,
          colorTemp.score,
          position.score,
          blur.intensity,
          glare.intensity,
          shadows.intensity,
        ),
      );
    } catch (e) {
      return LightingAnalysisResult.empty();
    }
  }

  /// Analyze exposure levels (histogram-based)
  _ExposureAnalysis _analyzeExposure(img.Image image) {
    final histogram = List<int>.filled(256, 0);
    int totalPixels = 0;

    // Build brightness histogram
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final brightness = ((pixel.r + pixel.g + pixel.b) / 3).round();
        histogram[brightness]++;
        totalPixels++;
      }
    }

    // Calculate statistics
    int sum = 0;
    for (int i = 0; i < 256; i++) {
      sum += histogram[i] * i;
    }
    final mean = sum / totalPixels;

    // Count underexposed and overexposed pixels
    final underexposed = histogram.sublist(0, 30).reduce((a, b) => a + b);
    final overexposed = histogram.sublist(226, 256).reduce((a, b) => a + b);
    final underexposedRatio = underexposed / totalPixels;
    final overexposedRatio = overexposed / totalPixels;

    // Determine exposure level
    ExposureLevel level;
    double score;

    if (underexposedRatio > 0.3) {
      level = ExposureLevel.tooLight;
      score = 0.3;
    } else if (overexposedRatio > 0.3) {
      level = ExposureLevel.tooDark;
      score = 0.3;
    } else if (mean >= 100 && mean <= 155) {
      level = ExposureLevel.perfect;
      score = 1.0;
    } else if (mean < 100) {
      level = ExposureLevel.slightlyDark;
      score = 0.7;
    } else {
      level = ExposureLevel.slightlyLight;
      score = 0.7;
    }

    return _ExposureAnalysis(level: level, score: score, mean: mean);
  }

  /// Analyze color temperature (white balance)
  _ColorTempAnalysis _analyzeColorTemperature(img.Image image) {
    int totalR = 0, totalG = 0, totalB = 0;
    int sampleCount = 0;

    // Sample center region (assume artwork is centered)
    final startX = (image.width * 0.25).round();
    final endX = (image.width * 0.75).round();
    final startY = (image.height * 0.25).round();
    final endY = (image.height * 0.75).round();

    for (int y = startY; y < endY; y += 4) {
      for (int x = startX; x < endX; x += 4) {
        final pixel = image.getPixel(x, y);
        totalR += pixel.r.toInt();
        totalG += pixel.g.toInt();
        totalB += pixel.b.toInt();
        sampleCount++;
      }
    }

    final avgR = totalR / sampleCount;
    final avgG = totalG / sampleCount;
    final avgB = totalB / sampleCount;

    // Estimate color temperature using simplified McCamy formula
    // This is approximate - real color temp needs calibrated sensor data
    final ratio = avgR / avgB;
    final kelvin = _estimateKelvin(ratio);

    // Score based on 4000-6000K target range
    final ColorTempLevel level;
    final double score;

    if (kelvin >= 4000 && kelvin <= 6000) {
      level = ColorTempLevel.perfect;
      score = 1.0;
    } else if (kelvin < 4000) {
      level = ColorTempLevel.tooWarm;
      score = math.max(0.3, 1.0 - (4000 - kelvin) / 2000);
    } else {
      level = ColorTempLevel.tooCool;
      score = math.max(0.3, 1.0 - (kelvin - 6000) / 2000);
    }

    return _ColorTempAnalysis(
      kelvin: kelvin,
      level: level,
      score: score,
    );
  }

  /// Estimate color temperature from R/B ratio (simplified)
  double _estimateKelvin(double ratio) {
    // Rough approximation based on typical R/B ratios
    if (ratio < 0.8) return 3000; // Very warm (incandescent)
    if (ratio < 1.0) return 4000; // Warm
    if (ratio < 1.2) return 5000; // Neutral (daylight)
    if (ratio < 1.4) return 6000; // Cool daylight
    return 7000; // Very cool (shade)
  }

  /// Analyze subject position in frame
  _PositionAnalysis _analyzePosition(img.Image image) {
    // Calculate brightness center of mass
    int centerX = 0, centerY = 0;
    int totalWeight = 0;

    for (int y = 0; y < image.height; y += 4) {
      for (int x = 0; x < image.width; x += 4) {
        final pixel = image.getPixel(x, y);
        final brightness = ((pixel.r + pixel.g + pixel.b) / 3).round();
        centerX += x * brightness;
        centerY += y * brightness;
        totalWeight += brightness;
      }
    }

    if (totalWeight == 0) {
      return _PositionAnalysis(
        horizontal: PositionHint.centered,
        vertical: PositionHint.centered,
        score: 1.0,
      );
    }

    centerX ~/= totalWeight;
    centerY ~/= totalWeight;

    // Calculate deviation from center
    final targetX = image.width / 2;
    final targetY = image.height / 2;
    final deviationX = (centerX - targetX).abs() / targetX;
    final deviationY = (centerY - targetY).abs() / targetY;

    // Determine horizontal position
    final PositionHint horizontal;
    if (deviationX < 0.1) {
      horizontal = PositionHint.centered;
    } else if (centerX < targetX) {
      horizontal = PositionHint.moveRight;
    } else {
      horizontal = PositionHint.moveLeft;
    }

    // Determine vertical position
    final PositionHint vertical;
    if (deviationY < 0.1) {
      vertical = PositionHint.centered;
    } else if (centerY < targetY) {
      vertical = PositionHint.moveDown;
    } else {
      vertical = PositionHint.moveUp;
    }

    // Calculate position score
    final score = 1.0 - (deviationX + deviationY) / 2;

    return _PositionAnalysis(
      horizontal: horizontal,
      vertical: vertical,
      score: score.clamp(0.0, 1.0),
    );
  }

  /// Detect motion blur using Laplacian variance
  _BlurAnalysis _detectMotionBlur(img.Image image) {
    // Sample center region
    final startX = (image.width * 0.3).round();
    final endX = (image.width * 0.7).round();
    final startY = (image.height * 0.3).round();
    final endY = (image.height * 0.7).round();

    double variance = 0;
    int count = 0;

    for (int y = startY + 1; y < endY - 1; y += 3) {
      for (int x = startX + 1; x < endX - 1; x += 3) {
        final pixel = image.getPixel(x, y);
        final brightness = (pixel.r + pixel.g + pixel.b) / 3;

        // Calculate Laplacian (edge sharpness)
        final neighbors = [
          image.getPixel(x - 1, y),
          image.getPixel(x + 1, y),
          image.getPixel(x, y - 1),
          image.getPixel(x, y + 1),
        ];

        double laplacian = brightness * 4;
        for (final n in neighbors) {
          laplacian -= (n.r + n.g + n.b) / 3;
        }

        variance += laplacian * laplacian;
        count++;
      }
    }

    variance /= count;

    // Low variance = blurry
    final detected = variance < 100;
    final intensity = detected ? (1.0 - variance / 100).clamp(0.0, 1.0) : 0.0;

    return _BlurAnalysis(detected: detected, intensity: intensity);
  }

  /// Detect glare/reflections (bright spots)
  _GlareAnalysis _detectGlare(img.Image image) {
    int glarePixels = 0;
    int totalPixels = 0;

    for (int y = 0; y < image.height; y += 3) {
      for (int x = 0; x < image.width; x += 3) {
        final pixel = image.getPixel(x, y);
        final brightness = (pixel.r + pixel.g + pixel.b) / 3;

        if (brightness > 240) {
          glarePixels++;
        }
        totalPixels++;
      }
    }

    final glareRatio = glarePixels / totalPixels;
    final detected = glareRatio > 0.05;
    final intensity = (glareRatio * 10).clamp(0.0, 1.0);

    return _GlareAnalysis(detected: detected, intensity: intensity);
  }

  /// Detect harsh shadows (dark regions with high contrast)
  _ShadowAnalysis _detectShadows(img.Image image) {
    int darkPixels = 0;
    int totalPixels = 0;
    double contrastSum = 0;

    for (int y = 1; y < image.height - 1; y += 3) {
      for (int x = 1; x < image.width - 1; x += 3) {
        final pixel = image.getPixel(x, y);
        final brightness = (pixel.r + pixel.g + pixel.b) / 3;

        if (brightness < 40) {
          darkPixels++;

          // Check contrast with neighbors
          final right = image.getPixel(x + 1, y);
          final rightBrightness = (right.r + right.g + right.b) / 3;
          contrastSum += (rightBrightness - brightness).abs();
        }
        totalPixels++;
      }
    }

    final darkRatio = darkPixels / totalPixels;
    final avgContrast = darkPixels > 0 ? contrastSum / darkPixels : 0;

    final detected = darkRatio > 0.1 && avgContrast > 50;
    final intensity = (darkRatio * 5).clamp(0.0, 1.0);

    return _ShadowAnalysis(detected: detected, intensity: intensity);
  }

  /// Calculate overall quality score
  double _calculateOverallScore(
    double exposureScore,
    double colorTempScore,
    double positionScore,
    double blurIntensity,
    double glareIntensity,
    double shadowIntensity,
  ) {
    // Weighted average with penalties
    final baseScore = (exposureScore * 0.3 +
            colorTempScore * 0.25 +
            positionScore * 0.25) /
        0.8;

    final penalties = (blurIntensity * 0.3 +
        glareIntensity * 0.2 +
        shadowIntensity * 0.2);

    return (baseScore - penalties).clamp(0.0, 1.0);
  }

  /// Convert YUV420 camera image to RGB (optimized for analysis)
  img.Image? _convertYUV420ToImage(CameraImage image) {
    try {
      final int width = image.width;
      final int height = image.height;

      final int uvRowStride = image.planes[1].bytesPerRow;
      final int uvPixelStride = image.planes[1].bytesPerPixel ?? 1;

      final rgbImage = img.Image(width: width, height: height);

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final int uvIndex =
              uvPixelStride * (x / 2).floor() + uvRowStride * (y / 2).floor();
          final int index = y * width + x;

          final yp = image.planes[0].bytes[index];
          final up = image.planes[1].bytes[uvIndex];
          final vp = image.planes[2].bytes[uvIndex];

          int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
          int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91)
              .round()
              .clamp(0, 255);
          int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);

          rgbImage.setPixelRgba(x, y, r, g, b, 255);
        }
      }

      return rgbImage;
    } catch (e) {
      return null;
    }
  }
}

// Helper classes
class _ExposureAnalysis {
  final ExposureLevel level;
  final double score;
  final double mean;

  _ExposureAnalysis({
    required this.level,
    required this.score,
    required this.mean,
  });
}

class _ColorTempAnalysis {
  final double kelvin;
  final ColorTempLevel level;
  final double score;

  _ColorTempAnalysis({
    required this.kelvin,
    required this.level,
    required this.score,
  });
}

class _PositionAnalysis {
  final PositionHint horizontal;
  final PositionHint vertical;
  final double score;

  _PositionAnalysis({
    required this.horizontal,
    required this.vertical,
    required this.score,
  });
}

class _BlurAnalysis {
  final bool detected;
  final double intensity;

  _BlurAnalysis({required this.detected, required this.intensity});
}

class _GlareAnalysis {
  final bool detected;
  final double intensity;

  _GlareAnalysis({required this.detected, required this.intensity});
}

class _ShadowAnalysis {
  final bool detected;
  final double intensity;

  _ShadowAnalysis({required this.detected, required this.intensity});
}

// Result classes
class LightingAnalysisResult {
  final ExposureLevel exposureLevel;
  final double exposureScore;
  final double colorTemperature;
  final double colorTempScore;
  final PositionHint positionHorizontal;
  final PositionHint positionVertical;
  final double positionScore;
  final bool hasMotionBlur;
  final double blurIntensity;
  final bool hasGlare;
  final double glareIntensity;
  final bool hasShadows;
  final double shadowIntensity;
  final double overallScore;

  LightingAnalysisResult({
    required this.exposureLevel,
    required this.exposureScore,
    required this.colorTemperature,
    required this.colorTempScore,
    required this.positionHorizontal,
    required this.positionVertical,
    required this.positionScore,
    required this.hasMotionBlur,
    required this.blurIntensity,
    required this.hasGlare,
    required this.glareIntensity,
    required this.hasShadows,
    required this.shadowIntensity,
    required this.overallScore,
  });

  factory LightingAnalysisResult.empty() {
    return LightingAnalysisResult(
      exposureLevel: ExposureLevel.perfect,
      exposureScore: 1.0,
      colorTemperature: 5000,
      colorTempScore: 1.0,
      positionHorizontal: PositionHint.centered,
      positionVertical: PositionHint.centered,
      positionScore: 1.0,
      hasMotionBlur: false,
      blurIntensity: 0.0,
      hasGlare: false,
      glareIntensity: 0.0,
      hasShadows: false,
      shadowIntensity: 0.0,
      overallScore: 1.0,
    );
  }

  /// Get primary issue to display
  String? getPrimaryIssue() {
    if (hasMotionBlur && blurIntensity > 0.5) return 'Hold camera steady';
    if (hasGlare && glareIntensity > 0.5) return 'Glare detected - adjust angle';
    if (hasShadows && shadowIntensity > 0.5) return 'Harsh shadows - adjust lighting';
    if (exposureScore < 0.5) {
      if (exposureLevel == ExposureLevel.tooDark) return 'Too dark - add light';
      if (exposureLevel == ExposureLevel.tooLight) return 'Too bright - reduce light';
    }
    if (colorTempScore < 0.6) {
      if (colorTemperature < 4000) return 'Lighting too warm (yellow)';
      if (colorTemperature > 6000) return 'Lighting too cool (blue)';
    }
    return null;
  }

  /// Get positioning guidance
  String? getPositionGuidance() {
    final hints = <String>[];
    if (positionVertical == PositionHint.moveUp) hints.add('Move camera up');
    if (positionVertical == PositionHint.moveDown) hints.add('Move camera down');
    if (positionHorizontal == PositionHint.moveLeft) hints.add('Move camera left');
    if (positionHorizontal == PositionHint.moveRight) hints.add('Move camera right');
    
    return hints.isEmpty ? null : hints.join(' • ');
  }

  /// Get quality rating
  QualityRating getQualityRating() {
    if (overallScore >= 0.8) return QualityRating.excellent;
    if (overallScore >= 0.6) return QualityRating.good;
    if (overallScore >= 0.4) return QualityRating.fair;
    return QualityRating.poor;
  }
}

// Enums
enum ExposureLevel {
  tooDark,
  slightlyDark,
  perfect,
  slightlyLight,
  tooLight,
}

enum ColorTempLevel {
  tooWarm,
  perfect,
  tooCool,
}

enum PositionHint {
  moveUp,
  moveDown,
  moveLeft,
  moveRight,
  centered,
}

enum QualityRating {
  excellent,
  good,
  fair,
  poor,
}
