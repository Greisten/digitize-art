import 'package:flutter/material.dart';
import '../services/edge_detection_service.dart';

class AROverlay extends StatelessWidget {
  final EdgeDetectionResult? detection;

  const AROverlay({
    super.key,
    this.detection,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: AROverlayPainter(detection: detection),
      size: Size.infinite,
    );
  }
}

class AROverlayPainter extends CustomPainter {
  final EdgeDetectionResult? detection;

  AROverlayPainter({this.detection});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw grid overlay for framing
    _drawGrid(canvas, size);

    // Draw detected edges if available
    if (detection?.hasDetection ?? false) {
      _drawDetectedCorners(canvas, size);
    }

    // Draw center guideline
    _drawCenterGuides(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Rule of thirds grid
    final thirdWidth = size.width / 3;
    final thirdHeight = size.height / 3;

    // Vertical lines
    canvas.drawLine(
      Offset(thirdWidth, 0),
      Offset(thirdWidth, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(thirdWidth * 2, 0),
      Offset(thirdWidth * 2, size.height),
      paint,
    );

    // Horizontal lines
    canvas.drawLine(
      Offset(0, thirdHeight),
      Offset(size.width, thirdHeight),
      paint,
    );
    canvas.drawLine(
      Offset(0, thirdHeight * 2),
      Offset(size.width, thirdHeight * 2),
      paint,
    );
  }

  void _drawDetectedCorners(Canvas canvas, Size size) {
    if (detection?.corners.isEmpty ?? true) return;

    final paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = Colors.green.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    // Draw polygon from corners
    if (detection!.corners.length >= 3) {
      final path = Path();
      final firstCorner = detection!.corners.first;
      path.moveTo(
        firstCorner.x * size.width,
        firstCorner.y * size.height,
      );

      for (var i = 1; i < detection!.corners.length; i++) {
        final corner = detection!.corners[i];
        path.lineTo(
          corner.x * size.width,
          corner.y * size.height,
        );
      }

      path.close();
      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, paint);
    }

    // Draw corner markers
    final cornerPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;

    for (final corner in detection!.corners) {
      canvas.drawCircle(
        Offset(corner.x * size.width, corner.y * size.height),
        8,
        cornerPaint,
      );
    }
  }

  void _drawCenterGuides(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final crossSize = 20.0;

    // Vertical center line
    canvas.drawLine(
      Offset(centerX, centerY - crossSize),
      Offset(centerX, centerY + crossSize),
      paint,
    );

    // Horizontal center line
    canvas.drawLine(
      Offset(centerX - crossSize, centerY),
      Offset(centerX + crossSize, centerY),
      paint,
    );
  }

  @override
  bool shouldRepaint(AROverlayPainter oldDelegate) {
    return oldDelegate.detection != detection;
  }
}
