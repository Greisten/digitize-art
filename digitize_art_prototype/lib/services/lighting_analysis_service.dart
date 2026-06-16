import 'dart:typed_data';
import 'dart:math' as math;
import 'package:camera/camera.dart';

/// Analyzes a live camera frame for lighting quality, positioning and issues.
///
/// Works directly on the luma (Y) plane of the camera frame, which exists on
/// both Android and iOS. (The previous full YUV->RGB conversion assumed an
/// Android-only 3-plane layout and silently failed on iOS, making the analysis
/// fall back to default "perfect" values regardless of the scene.) Color
/// temperature is estimated from the chroma plane(s), handling both the Android
/// (separate U/V planes) and iOS (interleaved CbCr) layouts.
class LightingAnalysisService {
  static const int _targetWidth = 160;

  Future<LightingAnalysisResult> analyze(CameraImage image) async {
    try {
      final luma = _downsampleLuma(image);
      if (luma == null) return LightingAnalysisResult.empty();

      final exposure = _analyzeExposure(luma);
      final colorTemp = _analyzeColorTemperature(image);
      final position = _analyzePosition(luma);
      final blur = _detectMotionBlur(luma);
      final glare = _detectGlare(luma);
      final shadows = _detectShadows(luma);
      final uniformity = _analyzeUniformity(luma);

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
        uniformityScore: uniformity.score,
        hasUnevenLighting: uniformity.detected,
        unevenHint: uniformity.hint,
        overallScore: _calculateOverallScore(
          exposure.score,
          colorTemp.score,
          position.score,
          uniformity.score,
          blur.intensity,
          glare.intensity,
          shadows.intensity,
        ),
      );
    } catch (e) {
      return LightingAnalysisResult.empty();
    }
  }

  /// Downsample the luma (Y) plane to a small grayscale buffer.
  _Luma? _downsampleLuma(CameraImage image) {
    if (image.planes.isEmpty) return null;
    final plane = image.planes[0];
    final bytes = plane.bytes;
    final int rowStride = plane.bytesPerRow;
    final int pixelStride = plane.bytesPerPixel ?? 1;
    final int sw = image.width;
    final int sh = image.height;
    if (sw <= 0 || sh <= 0) return null;

    final double scale = sw / _targetWidth;
    if (scale <= 0) return null;
    final int dw = _targetWidth;
    final int dh = math.max(1, (sh / scale).round());
    final data = Uint8List(dw * dh);

    for (int dy = 0; dy < dh; dy++) {
      final int sy = (dy * scale).floor().clamp(0, sh - 1);
      final int rowBase = sy * rowStride;
      final int dstBase = dy * dw;
      for (int dx = 0; dx < dw; dx++) {
        final int sx = (dx * scale).floor().clamp(0, sw - 1);
        data[dstBase + dx] = bytes[rowBase + sx * pixelStride];
      }
    }
    return _Luma(data, dw, dh);
  }

  /// Exposure from the luma histogram.
  _ExposureAnalysis _analyzeExposure(_Luma luma) {
    final data = luma.data;
    final histogram = List<int>.filled(256, 0);
    for (int i = 0; i < data.length; i++) {
      histogram[data[i]]++;
    }
    final total = data.length;

    int sum = 0;
    for (int i = 0; i < 256; i++) {
      sum += histogram[i] * i;
    }
    final mean = sum / total;

    int under = 0, over = 0;
    for (int i = 0; i < 30; i++) {
      under += histogram[i];
    }
    for (int i = 226; i < 256; i++) {
      over += histogram[i];
    }
    final underRatio = under / total;
    final overRatio = over / total;

    ExposureLevel level;
    double score;
    if (underRatio > 0.3) {
      level = ExposureLevel.tooDark;
      score = 0.25;
    } else if (overRatio > 0.3) {
      level = ExposureLevel.tooLight;
      score = 0.25;
    } else if (mean >= 100 && mean <= 165) {
      level = ExposureLevel.perfect;
      score = 1.0;
    } else if (mean < 100) {
      level = mean < 60 ? ExposureLevel.tooDark : ExposureLevel.slightlyDark;
      score = mean < 60 ? 0.4 : 0.7;
    } else {
      level = mean > 205 ? ExposureLevel.tooLight : ExposureLevel.slightlyLight;
      score = mean > 205 ? 0.4 : 0.7;
    }

    return _ExposureAnalysis(level: level, score: score, mean: mean);
  }

  /// Estimate color temperature from the chroma plane(s).
  _ColorTempAnalysis _analyzeColorTemperature(CameraImage image) {
    double kelvin = 5000;
    try {
      if (image.planes.length >= 2) {
        final p1 = image.planes[1];
        final b1 = p1.bytes;
        final int ps1 = p1.bytesPerPixel ?? 1;
        double sumCb = 0, sumCr = 0;
        int count = 0;

        if (image.planes.length >= 3 && ps1 == 1) {
          // Android: separate U(Cb) and V(Cr) planes.
          final b2 = image.planes[2].bytes;
          final int n = math.min(b1.length, b2.length);
          final int step = math.max(1, n ~/ 2000);
          for (int i = 0; i < n; i += step) {
            sumCb += b1[i];
            sumCr += b2[i];
            count++;
          }
        } else {
          // iOS: interleaved CbCr in plane 1 (Cb at even, Cr at odd).
          final int step = math.max(2, (b1.length ~/ 2000) * 2);
          for (int i = 0; i + 1 < b1.length; i += step) {
            sumCb += b1[i];
            sumCr += b1[i + 1];
            count++;
          }
        }

        if (count > 0) {
          final double cb = sumCb / count; // ~blue
          final double cr = sumCr / count; // ~red
          // Warmth: more red & less blue => warmer (lower kelvin).
          final double warmth = (cr - 128) - (cb - 128);
          kelvin = (5000 - warmth * 60).clamp(2500.0, 8500.0);
        }
      }
    } catch (_) {
      kelvin = 5000;
    }

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

    return _ColorTempAnalysis(kelvin: kelvin, level: level, score: score);
  }

  /// Subject position from the luma brightness center of mass.
  _PositionAnalysis _analyzePosition(_Luma luma) {
    final data = luma.data;
    final w = luma.width, h = luma.height;
    int cx = 0, cy = 0, totalWeight = 0;
    for (int y = 0; y < h; y += 2) {
      final base = y * w;
      for (int x = 0; x < w; x += 2) {
        final b = data[base + x];
        cx += x * b;
        cy += y * b;
        totalWeight += b;
      }
    }
    if (totalWeight == 0) {
      return _PositionAnalysis(
        horizontal: PositionHint.centered,
        vertical: PositionHint.centered,
        score: 1.0,
      );
    }
    final centerX = cx / totalWeight;
    final centerY = cy / totalWeight;
    final targetX = w / 2;
    final targetY = h / 2;
    final devX = (centerX - targetX).abs() / targetX;
    final devY = (centerY - targetY).abs() / targetY;

    final PositionHint horizontal;
    if (devX < 0.12) {
      horizontal = PositionHint.centered;
    } else if (centerX < targetX) {
      horizontal = PositionHint.moveRight;
    } else {
      horizontal = PositionHint.moveLeft;
    }
    final PositionHint vertical;
    if (devY < 0.12) {
      vertical = PositionHint.centered;
    } else if (centerY < targetY) {
      vertical = PositionHint.moveDown;
    } else {
      vertical = PositionHint.moveUp;
    }
    final score = (1.0 - (devX + devY) / 2).clamp(0.0, 1.0);
    return _PositionAnalysis(
      horizontal: horizontal,
      vertical: vertical,
      score: score,
    );
  }

  /// Motion blur via Laplacian variance on the center region.
  _BlurAnalysis _detectMotionBlur(_Luma luma) {
    final data = luma.data;
    final w = luma.width, h = luma.height;
    final sx = (w * 0.3).round(), ex = (w * 0.7).round();
    final sy = (h * 0.3).round(), ey = (h * 0.7).round();
    double variance = 0;
    int count = 0;
    for (int y = sy + 1; y < ey - 1; y++) {
      final base = y * w;
      for (int x = sx + 1; x < ex - 1; x++) {
        final c = data[base + x];
        final lap = c * 4 -
            data[base + x - 1] -
            data[base + x + 1] -
            data[base - w + x] -
            data[base + w + x];
        variance += lap * lap;
        count++;
      }
    }
    if (count == 0) return _BlurAnalysis(detected: false, intensity: 0.0);
    variance /= count;
    final detected = variance < 80;
    final intensity = detected ? (1.0 - variance / 80).clamp(0.0, 1.0) : 0.0;
    return _BlurAnalysis(detected: detected, intensity: intensity);
  }

  /// Glare from bright (near-white) pixels.
  _GlareAnalysis _detectGlare(_Luma luma) {
    final data = luma.data;
    int glare = 0;
    for (int i = 0; i < data.length; i++) {
      if (data[i] > 244) glare++;
    }
    final ratio = glare / data.length;
    final detected = ratio > 0.04;
    final intensity = (ratio * 12).clamp(0.0, 1.0);
    return _GlareAnalysis(detected: detected, intensity: intensity);
  }

  /// Harsh shadows: dark, high-contrast regions.
  _ShadowAnalysis _detectShadows(_Luma luma) {
    final data = luma.data;
    final w = luma.width, h = luma.height;
    int dark = 0;
    double contrastSum = 0;
    int total = 0;
    for (int y = 1; y < h - 1; y++) {
      final base = y * w;
      for (int x = 1; x < w - 1; x++) {
        final b = data[base + x];
        if (b < 40) {
          dark++;
          contrastSum += (data[base + x + 1] - b).abs();
        }
        total++;
      }
    }
    if (total == 0) return _ShadowAnalysis(detected: false, intensity: 0.0);
    final darkRatio = dark / total;
    final avgContrast = dark > 0 ? contrastSum / dark : 0;
    final detected = darkRatio > 0.1 && avgContrast > 45;
    final intensity = (darkRatio * 4).clamp(0.0, 1.0);
    return _ShadowAnalysis(detected: detected, intensity: intensity);
  }

  /// Lighting uniformity across a 3x3 zone grid, with a directional hint for
  /// which side is darker.
  _UniformityAnalysis _analyzeUniformity(_Luma luma) {
    final data = luma.data;
    final w = luma.width, h = luma.height;
    final startX = (w * 0.05).round(), endX = (w * 0.95).round();
    final startY = (h * 0.05).round(), endY = (h * 0.95).round();
    final regionW = endX - startX, regionH = endY - startY;
    if (regionW <= 3 || regionH <= 3) {
      return _UniformityAnalysis(
          score: 1.0, detected: false, hint: UnevenLightingHint.none);
    }
    final zoneSums = List<double>.filled(9, 0);
    final zoneCounts = List<int>.filled(9, 0);
    for (int y = startY; y < endY; y++) {
      final zy = (((y - startY) * 3) ~/ regionH).clamp(0, 2);
      final base = y * w;
      for (int x = startX; x < endX; x++) {
        final zx = (((x - startX) * 3) ~/ regionW).clamp(0, 2);
        final idx = zy * 3 + zx;
        zoneSums[idx] += data[base + x];
        zoneCounts[idx]++;
      }
    }
    final zoneMeans = List<double>.generate(
        9, (i) => zoneCounts[i] > 0 ? zoneSums[i] / zoneCounts[i] : 0.0);
    final maxMean = zoneMeans.reduce(math.max);
    final minMean = zoneMeans.reduce(math.min);
    final avg = zoneMeans.reduce((a, b) => a + b) / 9;
    if (avg <= 0) {
      return _UniformityAnalysis(
          score: 1.0, detected: false, hint: UnevenLightingHint.none);
    }
    final spread = (maxMean - minMean) / avg;
    final score = (1 - spread / 0.5).clamp(0.0, 1.0);
    final detected = spread > 0.25;

    final leftMean = (zoneMeans[0] + zoneMeans[3] + zoneMeans[6]) / 3;
    final rightMean = (zoneMeans[2] + zoneMeans[5] + zoneMeans[8]) / 3;
    final topMean = (zoneMeans[0] + zoneMeans[1] + zoneMeans[2]) / 3;
    final bottomMean = (zoneMeans[6] + zoneMeans[7] + zoneMeans[8]) / 3;
    final hDiff = leftMean - rightMean;
    final vDiff = topMean - bottomMean;
    var hint = UnevenLightingHint.none;
    if (detected) {
      if (hDiff.abs() >= vDiff.abs()) {
        hint = hDiff < 0
            ? UnevenLightingHint.leftDarker
            : UnevenLightingHint.rightDarker;
      } else {
        hint = vDiff < 0
            ? UnevenLightingHint.topDarker
            : UnevenLightingHint.bottomDarker;
      }
    }
    return _UniformityAnalysis(score: score, detected: detected, hint: hint);
  }

  double _calculateOverallScore(
    double exposureScore,
    double colorTempScore,
    double positionScore,
    double uniformityScore,
    double blurIntensity,
    double glareIntensity,
    double shadowIntensity,
  ) {
    // Weighted average with penalties (weights sum to 1.0).
    final baseScore = exposureScore * 0.3 +
        colorTempScore * 0.2 +
        positionScore * 0.2 +
        uniformityScore * 0.3;

    final penalties = (blurIntensity * 0.3 +
        glareIntensity * 0.2 +
        shadowIntensity * 0.2);

    return (baseScore - penalties).clamp(0.0, 1.0);
  }
}

/// Small downsampled luma (grayscale) buffer.
class _Luma {
  final Uint8List data;
  final int width;
  final int height;

  _Luma(this.data, this.width, this.height);
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

class _UniformityAnalysis {
  final double score;
  final bool detected;
  final UnevenLightingHint hint;

  _UniformityAnalysis({
    required this.score,
    required this.detected,
    required this.hint,
  });
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
  final double uniformityScore;
  final bool hasUnevenLighting;
  final UnevenLightingHint unevenHint;
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
    required this.uniformityScore,
    required this.hasUnevenLighting,
    required this.unevenHint,
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
      uniformityScore: 1.0,
      hasUnevenLighting: false,
      unevenHint: UnevenLightingHint.none,
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
    if (hasUnevenLighting && uniformityScore < 0.5) {
      return getUniformityGuidance();
    }
    if (colorTempScore < 0.6) {
      if (colorTemperature < 4000) return 'Lighting too warm (yellow)';
      if (colorTemperature > 6000) return 'Lighting too cool (blue)';
    }
    return null;
  }

  /// Directional guidance for uneven lighting (e.g. "Uneven light - brighten
  /// the left side").
  String? getUniformityGuidance() {
    switch (unevenHint) {
      case UnevenLightingHint.leftDarker:
        return 'Uneven light - brighten the left side';
      case UnevenLightingHint.rightDarker:
        return 'Uneven light - brighten the right side';
      case UnevenLightingHint.topDarker:
        return 'Uneven light - brighten the top';
      case UnevenLightingHint.bottomDarker:
        return 'Uneven light - brighten the bottom';
      case UnevenLightingHint.none:
        return null;
    }
  }

  /// Short label of which side is darker, for compact display.
  String unevenSideLabel() {
    switch (unevenHint) {
      case UnevenLightingHint.leftDarker:
        return 'left darker';
      case UnevenLightingHint.rightDarker:
        return 'right darker';
      case UnevenLightingHint.topDarker:
        return 'top darker';
      case UnevenLightingHint.bottomDarker:
        return 'bottom darker';
      case UnevenLightingHint.none:
        return 'uneven';
    }
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

enum UnevenLightingHint {
  none,
  leftDarker,
  rightDarker,
  topDarker,
  bottomDarker,
}
