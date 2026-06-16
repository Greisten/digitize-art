import 'dart:typed_data';
import 'dart:math' as math;
import 'package:camera/camera.dart';

/// Detects the quadrilateral of an artwork in a live camera frame.
///
/// The frame is downsampled to a small luma image and a Sobel gradient is
/// computed; the artwork's outer border is then located from the edge
/// projection peaks. Working on a ~160px-wide luma buffer (instead of a
/// full-resolution RGB conversion) keeps per-frame cost low enough for the
/// real-time camera stream.
class EdgeDetectionService {
  /// Downsample target width for fast per-frame analysis.
  static const int _targetWidth = 160;

  /// Minimum confidence before we report a usable detection.
  static const double _detectionThreshold = 0.4;

  /// Detect the artwork quadrilateral in [image].
  ///
  /// [sensorOrientation] is the camera sensor orientation in degrees
  /// (0/90/180/270). Detected corners are rotated by it so they line up with
  /// the upright camera preview.
  Future<EdgeDetectionResult> detectEdges(
    CameraImage image, {
    int sensorOrientation = 90,
  }) async {
    try {
      final gray = _downsampleLuma(image);
      if (gray == null) return EdgeDetectionResult.empty();

      final quad = _findArtworkQuad(gray.data, gray.width, gray.height);
      if (quad == null) return EdgeDetectionResult.empty();

      // Rotate the corners into the preview's coordinate space, then re-order
      // them as top-left, top-right, bottom-right, bottom-left so the overlay
      // draws a clean, non-self-intersecting polygon.
      final corners = _orderCorners(
        quad.corners.map((c) => _rotate(c, sensorOrientation)).toList(),
      );

      final detected = quad.confidence >= _detectionThreshold;
      return EdgeDetectionResult(
        hasDetection: detected,
        corners: detected ? corners : const [],
        confidence: quad.confidence,
      );
    } catch (e) {
      return EdgeDetectionResult.empty();
    }
  }

  /// Build a small grayscale buffer from the camera frame's luma (Y) plane.
  ///
  /// The Y plane already holds per-pixel brightness, so no YUV->RGB conversion
  /// is needed for edge detection.
  _Gray? _downsampleLuma(CameraImage image) {
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

    return _Gray(data, dw, dh);
  }

  /// Locate the artwork's bounding quadrilateral from a grayscale buffer.
  _QuadResult? _findArtworkQuad(Uint8List gray, int w, int h) {
    if (w < 8 || h < 8) return null;

    final rowSum = Float64List(h);
    final colSum = Float64List(w);
    double total = 0;

    // Sobel gradient magnitude, accumulated into row/column edge projections.
    for (int y = 1; y < h - 1; y++) {
      final int r0 = (y - 1) * w;
      final int r1 = y * w;
      final int r2 = (y + 1) * w;
      for (int x = 1; x < w - 1; x++) {
        final int tl = gray[r0 + x - 1];
        final int tc = gray[r0 + x];
        final int tr = gray[r0 + x + 1];
        final int ml = gray[r1 + x - 1];
        final int mr = gray[r1 + x + 1];
        final int bl = gray[r2 + x - 1];
        final int bc = gray[r2 + x];
        final int br = gray[r2 + x + 1];

        final int gx = (tr + 2 * mr + br) - (tl + 2 * ml + bl);
        final int gy = (bl + 2 * bc + br) - (tl + 2 * tc + tr);
        final double mag = (gx.abs() + gy.abs()).toDouble();

        rowSum[y] += mag;
        colSum[x] += mag;
        total += mag;
      }
    }

    if (total <= 0) return null;

    final bounds = _projectionBounds(rowSum, colSum, w, h);
    if (bounds == null) return null;

    final int left = bounds[0];
    final int right = bounds[1];
    final int top = bounds[2];
    final int bottom = bounds[3];

    final double boxW = (right - left).toDouble();
    final double boxH = (bottom - top).toDouble();
    // Reject boxes that are too small to be a real artwork in frame.
    if (boxW < w * 0.12 || boxH < h * 0.12) return null;

    // Area score: favor an artwork filling 20%-90% of the frame.
    final double areaRatio = (boxW * boxH) / (w * h);
    final double areaScore;
    if (areaRatio >= 0.2 && areaRatio <= 0.9) {
      areaScore = 1.0;
    } else if (areaRatio < 0.2) {
      areaScore = areaRatio / 0.2;
    } else {
      areaScore = math.max(0.0, 1 - (areaRatio - 0.9) / 0.1);
    }

    // Strength score: how strong the border projection peaks are relative to
    // the average edge energy.
    final double meanRow = total / h;
    final double borderStrength =
        (rowSum[top] + rowSum[bottom] + colSum[left] + colSum[right]) / 4;
    final double strengthScore =
        meanRow <= 0 ? 0.0 : (borderStrength / (meanRow * 3)).clamp(0.0, 1.0);

    final double confidence =
        (areaScore * 0.6 + strengthScore * 0.4).clamp(0.0, 1.0);

    final corners = <Corner>[
      Corner(left / w, top / h),
      Corner(right / w, top / h),
      Corner(right / w, bottom / h),
      Corner(left / w, bottom / h),
    ];

    return _QuadResult(corners, confidence);
  }

  /// Find the outermost rows/columns whose edge projection exceeds 30% of the
  /// strongest projection. Returns `[left, right, top, bottom]`.
  List<int>? _projectionBounds(
    Float64List rowSum,
    Float64List colSum,
    int w,
    int h,
  ) {
    double maxRow = 0;
    double maxCol = 0;
    for (int y = 0; y < h; y++) {
      if (rowSum[y] > maxRow) maxRow = rowSum[y];
    }
    for (int x = 0; x < w; x++) {
      if (colSum[x] > maxCol) maxCol = colSum[x];
    }
    if (maxRow <= 0 || maxCol <= 0) return null;

    final double rowThr = maxRow * 0.30;
    final double colThr = maxCol * 0.30;

    int top = -1, bottom = -1, left = -1, right = -1;
    for (int y = 0; y < h; y++) {
      if (rowSum[y] >= rowThr) {
        if (top < 0) top = y;
        bottom = y;
      }
    }
    for (int x = 0; x < w; x++) {
      if (colSum[x] >= colThr) {
        if (left < 0) left = x;
        right = x;
      }
    }

    if (top < 0 || left < 0 || bottom <= top || right <= left) return null;
    return [left, right, top, bottom];
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
class _Gray {
  final Uint8List data;
  final int width;
  final int height;

  _Gray(this.data, this.width, this.height);
}

/// Internal detection result before orientation handling.
class _QuadResult {
  final List<Corner> corners;
  final double confidence;

  _QuadResult(this.corners, this.confidence);
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
