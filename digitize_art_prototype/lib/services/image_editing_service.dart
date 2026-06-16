import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Applies non-destructive edits (perspective correction, brightness/contrast/
/// saturation, rotation) to a captured scan and writes the result to a new
/// temp file. The heavy pixel work runs in a background isolate via [compute].
class ImageEditingService {
  Future<String> applyAndSave({
    required String sourcePath,
    required List<double> corners, // 8 values: TL,TR,BR,BL (normalized 0..1)
    required double brightness,
    required double contrast,
    required double saturation,
    required int quarterTurns,
  }) async {
    final bytes = await File(sourcePath).readAsBytes();

    final params = EditParams(
      bytes: bytes,
      corners: corners,
      brightness: brightness,
      contrast: contrast,
      saturation: saturation,
      quarterTurns: quarterTurns,
    );

    final out = await compute(_applyEdits, params);

    final dir = await getTemporaryDirectory();
    final path = p.join(
      dir.path,
      'edit_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await File(path).writeAsBytes(out);
    return path;
  }
}

/// Sendable parameter bundle for the background isolate.
class EditParams {
  final Uint8List bytes;
  final List<double> corners;
  final double brightness;
  final double contrast;
  final double saturation;
  final int quarterTurns;

  EditParams({
    required this.bytes,
    required this.corners,
    required this.brightness,
    required this.contrast,
    required this.saturation,
    required this.quarterTurns,
  });
}

/// Runs in a background isolate. Returns encoded JPEG bytes.
Uint8List _applyEdits(EditParams params) {
  var image = img.decodeImage(params.bytes);
  if (image == null) return params.bytes;
  image = img.bakeOrientation(image);

  // Perspective correction / crop. Rectify the user quad to a rectangle whose
  // size matches the quad's own edge lengths, so the artwork keeps its real
  // proportions instead of being stretched to fill the whole source frame.
  if (params.corners.length == 8 && !_isFullFrame(params.corners)) {
    final int w = image.width;
    final int h = image.height;
    final c = params.corners;

    final double tlx = c[0] * w, tly = c[1] * h;
    final double trx = c[2] * w, tryy = c[3] * h;
    final double brx = c[4] * w, bry = c[5] * h;
    final double blx = c[6] * w, bly = c[7] * h;

    double dist(double ax, double ay, double bx, double by) =>
        math.sqrt((ax - bx) * (ax - bx) + (ay - by) * (ay - by));

    final double topLen = dist(tlx, tly, trx, tryy);
    final double bottomLen = dist(blx, bly, brx, bry);
    final double leftLen = dist(tlx, tly, blx, bly);
    final double rightLen = dist(trx, tryy, brx, bry);

    final int outW = math.max(1, ((topLen + bottomLen) / 2).round());
    final int outH = math.max(1, ((leftLen + rightLen) / 2).round());

    image = img.copyRectify(
      image,
      topLeft: img.Point(tlx, tly),
      topRight: img.Point(trx, tryy),
      bottomRight: img.Point(brx, bry),
      bottomLeft: img.Point(blx, bly),
      toImage: img.Image(width: outW, height: outH),
    );
  }

  // Brightness / contrast / saturation, in place. Same math as the live
  // preview (see EditScreen's color matrices) so the result matches.
  final double br = params.brightness;
  final double ct = params.contrast;
  final double sa = params.saturation;
  if (br != 1.0 || ct != 1.0 || sa != 1.0) {
    for (final pixel in image) {
      double r = pixel.r.toDouble();
      double g = pixel.g.toDouble();
      double b = pixel.b.toDouble();

      // Brightness (multiplicative).
      r *= br;
      g *= br;
      b *= br;

      // Contrast around mid-gray.
      r = (r - 128) * ct + 128;
      g = (g - 128) * ct + 128;
      b = (b - 128) * ct + 128;

      // Saturation around luma.
      final double lum = 0.2126 * r + 0.7152 * g + 0.0722 * b;
      r = lum + (r - lum) * sa;
      g = lum + (g - lum) * sa;
      b = lum + (b - lum) * sa;

      pixel.setRgb(
        r.round().clamp(0, 255),
        g.round().clamp(0, 255),
        b.round().clamp(0, 255),
      );
    }
  }

  final int turns = params.quarterTurns % 4;
  if (turns != 0) {
    image = img.copyRotate(image, angle: turns * 90);
  }

  return img.encodeJpg(image, quality: 95);
}

/// Treat near-full-frame corners (within 1%) as "no crop".
bool _isFullFrame(List<double> c) {
  const double e = 0.01;
  return c[0] < e &&
      c[1] < e && // TL ~ (0,0)
      c[2] > 1 - e &&
      c[3] < e && // TR ~ (1,0)
      c[4] > 1 - e &&
      c[5] > 1 - e && // BR ~ (1,1)
      c[6] < e &&
      c[7] > 1 - e; // BL ~ (0,1)
}
