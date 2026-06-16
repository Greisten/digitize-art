import 'dart:io';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Captures a bracketed set of exposures and fuses them into a single
/// well-exposed image (multi-shot HDR).
///
/// On devices that expose an exposure-compensation range, three shots are
/// taken at low / normal / high exposure. They are then combined with a
/// simplified Mertens-style exposure fusion that, per pixel, favors the shot
/// where that pixel is best exposed (closest to mid-gray). The fusion runs in
/// a background isolate so the UI stays responsive.
class HdrCaptureService {
  /// Fraction of the device exposure range used for the bracket extremes.
  /// Staying short of the limits avoids hard clipping in the dark/bright shots.
  static const double _bracketSpread = 0.7;

  /// Settle time after changing exposure before taking the shot.
  static const Duration _settleDelay = Duration(milliseconds: 450);

  Future<HdrCaptureResult> captureHdr(CameraController controller) async {
    double minOffset = 0;
    double maxOffset = 0;
    try {
      minOffset = await controller.getMinExposureOffset();
      maxOffset = await controller.getMaxExposureOffset();
    } catch (_) {
      // Device doesn't report a range; fall back to a single normal shot.
    }

    final bool bracketed = (maxOffset - minOffset).abs() > 0.1;
    final List<double> offsets = bracketed
        ? <double>[minOffset * _bracketSpread, 0.0, maxOffset * _bracketSpread]
        : <double>[0.0];

    final List<Uint8List> shots = [];
    try {
      for (final offset in offsets) {
        if (bracketed) {
          await controller.setExposureOffset(offset);
          await Future.delayed(_settleDelay);
        }
        final file = await controller.takePicture();
        shots.add(await file.readAsBytes());
      }
    } finally {
      if (bracketed) {
        // Restore neutral exposure for the live preview.
        try {
          await controller.setExposureOffset(0.0);
        } catch (_) {}
      }
    }

    // Fuse off the UI thread.
    final Uint8List fusedBytes = await compute(_fuseExposures, shots);

    final dir = await getTemporaryDirectory();
    final path = p.join(
      dir.path,
      'hdr_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await File(path).writeAsBytes(fusedBytes);

    return HdrCaptureResult(
      path: path,
      exposureCount: shots.length,
      fused: shots.length > 1,
      bracketed: bracketed,
    );
  }
}

/// Exposure fusion. Runs in a background isolate via [compute].
///
/// Takes the encoded JPEG bytes of each bracketed shot and returns the encoded
/// JPEG bytes of the fused result.
Uint8List _fuseExposures(List<Uint8List> jpegs) {
  final images = <img.Image>[];
  for (final bytes in jpegs) {
    final decoded = img.decodeJpg(bytes);
    if (decoded != null) {
      images.add(img.bakeOrientation(decoded));
    }
  }

  if (images.isEmpty) return jpegs.first;
  if (images.length == 1) return img.encodeJpg(images.first, quality: 95);

  // Work at the smallest common size in case shots differ by a pixel.
  int w = images.first.width;
  int h = images.first.height;
  for (final im in images) {
    w = math.min(w, im.width);
    h = math.min(h, im.height);
  }

  final result = img.Image(width: w, height: h);

  // Well-exposedness weight: a Gaussian centered on mid-gray (0.5).
  const double sigma = 0.2;
  const double denom = 2 * sigma * sigma;
  const double eps = 1e-6;

  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      double sumW = 0, rAcc = 0, gAcc = 0, bAcc = 0;
      for (final im in images) {
        final px = im.getPixel(x, y);
        final double r = px.r.toDouble();
        final double g = px.g.toDouble();
        final double b = px.b.toDouble();
        final double lum = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0;
        final double d = lum - 0.5;
        final double weight = math.exp(-(d * d) / denom) + eps;
        sumW += weight;
        rAcc += r * weight;
        gAcc += g * weight;
        bAcc += b * weight;
      }
      result.setPixelRgb(
        x,
        y,
        (rAcc / sumW).round().clamp(0, 255),
        (gAcc / sumW).round().clamp(0, 255),
        (bAcc / sumW).round().clamp(0, 255),
      );
    }
  }

  return img.encodeJpg(result, quality: 95);
}

class HdrCaptureResult {
  /// Temp-file path of the saved (fused) image.
  final String path;

  /// Number of exposures actually captured.
  final int exposureCount;

  /// Whether multiple exposures were fused (vs a single fallback shot).
  final bool fused;

  /// Whether the device supported exposure bracketing.
  final bool bracketed;

  HdrCaptureResult({
    required this.path,
    required this.exposureCount,
    required this.fused,
    required this.bracketed,
  });
}
