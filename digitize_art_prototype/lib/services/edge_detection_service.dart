import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;

/// Detects the quadrilateral of an artwork in a live camera frame using OpenCV.
///
/// Pipeline (the classic document-scanner approach): downsample the luma (Y)
/// plane to a grayscale Mat, blur, Canny edge detection, then find the largest
/// 4-point convex-ish contour via findContours + approxPolyDP. Much more
/// robust than a pure-Dart heuristic, especially at an angle.
///
/// The public API (EdgeDetectionResult / Corner / detectEdges) is unchanged so
/// the camera screen and AR overlay keep working as-is.
class EdgeDetectionService {
  /// Downsample target width (OpenCV is fast enough for a larger buffer than
  /// the old Dart path, which improves corner accuracy).
  static const int _targetWidth = 300;

  /// Minimum quad area (fraction of the frame) to count as an artwork.
  static const double _minAreaRatio = 0.12;

  Future<EdgeDetectionResult> detectEdges(
    CameraImage image, {
    int sensorOrientation = 90,
  }) async {
    cv.Mat? gray;
    cv.Mat? blurred;
    cv.Mat? edges;
    cv.Mat? kernel;
    cv.Mat? dilated;
    cv.Contours? contours;
    cv.VecVec4i? hierarchy;

    try {
      final luma = _downsampleLuma(image);
      if (luma == null) return EdgeDetectionResult.empty();

      gray = cv.Mat.fromList(
        luma.height,
        luma.width,
        cv.MatType.CV_8UC1,
        luma.data,
      );
      blurred = cv.gaussianBlur(gray, (5, 5), 0);
      edges = cv.canny(blurred, 50, 150);

      // Close small gaps in the edges so the artwork outline forms a single
      // contour (Canny alone tends to leave breaks).
      kernel = cv.getStructuringElement(cv.MORPH_RECT, (5, 5));
      dilated = cv.dilate(edges, kernel, iterations: 1);

      final found = cv.findContours(
        dilated,
        cv.RETR_EXTERNAL,
        cv.CHAIN_APPROX_SIMPLE,
      );
      contours = found.$1;
      hierarchy = found.$2;

      final double frameArea = (luma.width * luma.height).toDouble();
      final double minArea = frameArea * _minAreaRatio;

      // Pick the largest contour above the size floor.
      double bestArea = 0;
      int bestIndex = -1;
      for (int i = 0; i < contours.length; i++) {
        final double area = cv.contourArea(contours[i]);
        if (area >= minArea && area > bestArea) {
          bestArea = area;
          bestIndex = i;
        }
      }

      if (bestIndex < 0) return EdgeDetectionResult.empty();

      final contour = contours[bestIndex];
      final double peri = cv.arcLength(contour, true);
      final approx = cv.approxPolyDP(contour, 0.02 * peri, true);

      List<Corner> quad;
      if (approx.length == 4) {
        // Clean quadrilateral.
        quad = [
          for (int j = 0; j < 4; j++)
            Corner(approx[j].x / luma.width, approx[j].y / luma.height),
        ];
      } else {
        // Fallback: minimum-area rotated rectangle around the largest object,
        // so we still report a usable quad when the outline isn't a clean 4-gon.
        final rotated = cv.minAreaRect(contour);
        final pts = rotated.points;
        quad = [
          for (int j = 0; j < 4; j++)
            Corner(pts[j].x / luma.width, pts[j].y / luma.height),
        ];
        pts.dispose();
        rotated.dispose();
      }
      approx.dispose();

      final corners = _orderCorners(
        quad.map((c) => _rotate(c, sensorOrientation)).toList(),
      );
      final confidence = (bestArea / frameArea).clamp(0.0, 1.0);

      return EdgeDetectionResult(
        hasDetection: true,
        corners: corners,
        confidence: confidence,
      );
    } catch (e) {
      return EdgeDetectionResult.empty();
    } finally {
      gray?.dispose();
      blurred?.dispose();
      edges?.dispose();
      kernel?.dispose();
      dilated?.dispose();
      contours?.dispose();
      hierarchy?.dispose();
    }
  }

  /// Build a small grayscale buffer from the camera frame's luma (Y) plane.
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
    final int dh = (sh / scale).round() < 1 ? 1 : (sh / scale).round();
    final data = Uint8List(dw * dh);

    for (int dy = 0; dy < dh; dy++) {
      int sy = (dy * scale).floor();
      if (sy > sh - 1) sy = sh - 1;
      final int rowBase = sy * rowStride;
      final int dstBase = dy * dw;
      for (int dx = 0; dx < dw; dx++) {
        int sx = (dx * scale).floor();
        if (sx > sw - 1) sx = sw - 1;
        data[dstBase + dx] = bytes[rowBase + sx * pixelStride];
      }
    }

    return _Luma(data, dw, dh);
  }

  /// Rotate a normalized corner by the sensor orientation so it matches the
  /// upright preview.
  Corner _rotate(Corner c, int orientation) {
    switch (orientation % 360) {
      case 90:
        return Corner(1 - c.y, c.x);
      case 180:
        return Corner(1 - c.x, 1 - c.y);
      case 270:
        return Corner(c.y, 1 - c.x);
      default:
        return c;
    }
  }

  /// Re-order four corners as [topLeft, topRight, bottomRight, bottomLeft].
  List<Corner> _orderCorners(List<Corner> pts) {
    if (pts.length != 4) return pts;

    Corner tl = pts[0], tr = pts[0], br = pts[0], bl = pts[0];
    double minSum = double.infinity, maxSum = -double.infinity;
    double minDiff = double.infinity, maxDiff = -double.infinity;

    for (final p in pts) {
      final double s = p.x + p.y;
      final double d = p.x - p.y;
      if (s < minSum) {
        minSum = s;
        tl = p;
      }
      if (s > maxSum) {
        maxSum = s;
        br = p;
      }
      if (d > maxDiff) {
        maxDiff = d;
        tr = p;
      }
      if (d < minDiff) {
        minDiff = d;
        bl = p;
      }
    }

    return [tl, tr, br, bl];
  }
}

/// Small grayscale buffer (row-major, one byte per pixel).
class _Luma {
  final Uint8List data;
  final int width;
  final int height;

  _Luma(this.data, this.width, this.height);
}

class EdgeDetectionResult {
  final bool hasDetection;
  final List<Corner> corners;
  final double confidence;

  EdgeDetectionResult({
    required this.hasDetection,
    required this.corners,
    required this.confidence,
  });

  factory EdgeDetectionResult.empty() {
    return EdgeDetectionResult(
      hasDetection: false,
      corners: const [],
      confidence: 0.0,
    );
  }
}

class Corner {
  final double x;
  final double y;

  Corner(this.x, this.y);
}
