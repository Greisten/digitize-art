import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../services/image_editing_service.dart';
import '../services/scan_storage_service.dart';
import '../theme/app_theme.dart';

/// Post-capture editor: perspective/crop with draggable corners, plus
/// brightness / contrast / saturation and 90° rotation. Saves the edited
/// result to the gallery and pops `true` on success.
class EditScreen extends StatefulWidget {
  final String imagePath;
  final bool isHdr;

  const EditScreen({
    super.key,
    required this.imagePath,
    this.isHdr = false,
  });

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  // Corners (normalized 0..1), ordered TL, TR, BR, BL.
  List<Offset> _corners = const [
    Offset(0, 0),
    Offset(1, 0),
    Offset(1, 1),
    Offset(0, 1),
  ];

  double _brightness = 1.0;
  double _contrast = 1.0;
  double _saturation = 1.0;
  int _quarterTurns = 0;

  int _tab = 0; // 0 = crop, 1 = adjust
  bool _isSaving = false;

  late Future<Size> _sizeFuture;

  @override
  void initState() {
    super.initState();
    _sizeFuture = _loadImageSize();
  }

  Future<Size> _loadImageSize() async {
    final bytes = await File(widget.imagePath).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final size = Size(image.width.toDouble(), image.height.toDouble());
    image.dispose();
    return size;
  }

  void _resetCorners() {
    setState(() {
      _corners = const [
        Offset(0, 0),
        Offset(1, 0),
        Offset(1, 1),
        Offset(0, 1),
      ];
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final corners = <double>[
        _corners[0].dx, _corners[0].dy,
        _corners[1].dx, _corners[1].dy,
        _corners[2].dx, _corners[2].dy,
        _corners[3].dx, _corners[3].dy,
      ];

      final editedPath = await ImageEditingService().applyAndSave(
        sourcePath: widget.imagePath,
        corners: corners,
        brightness: _brightness,
        contrast: _contrast,
        saturation: _saturation,
        quarterTurns: _quarterTurns,
      );

      await ScanStorageService().saveScan(
        sourcePath: editedPath,
        isHdr: widget.isHdr,
      );

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Échec de l\'enregistrement : $e'),
            backgroundColor: AppTheme.errorMain,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Édition'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Enreg.', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildEditingArea()),
          _buildTabBar(),
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildEditingArea() {
    return FutureBuilder<Size>(
      future: _sizeFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }
        final size = snapshot.data!;
        return _tab == 0 ? _buildCropArea(size) : _buildAdjustArea();
      },
    );
  }

  Widget _buildCropArea(Size imageSize) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: AspectRatio(
          aspectRatio: imageSize.width / imageSize.height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;
              return Stack(
                children: [
                  Positioned.fill(
                    child: Image.file(File(widget.imagePath), fit: BoxFit.fill),
                  ),
                  Positioned.fill(
                    child: CustomPaint(painter: _CropPainter(_corners)),
                  ),
                  for (int i = 0; i < _corners.length; i++)
                    _buildHandle(i, w, h),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHandle(int index, double boxW, double boxH) {
    const double r = 16;
    final corner = _corners[index];
    return Positioned(
      left: corner.dx * boxW - r,
      top: corner.dy * boxH - r,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            final next = Offset(
              (corner.dx + details.delta.dx / boxW).clamp(0.0, 1.0),
              (corner.dy + details.delta.dy / boxH).clamp(0.0, 1.0),
            );
            final updated = List<Offset>.from(_corners);
            updated[index] = next;
            _corners = updated;
          });
        },
        child: Container(
          width: r * 2,
          height: r * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.secondaryMain.withOpacity(0.5),
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildAdjustArea() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: RotatedBox(
          quarterTurns: _quarterTurns,
          child: ColorFiltered(
            colorFilter: ColorFilter.matrix(_saturationMatrix(_saturation)),
            child: ColorFiltered(
              colorFilter: ColorFilter.matrix(_contrastMatrix(_contrast)),
              child: ColorFiltered(
                colorFilter: ColorFilter.matrix(_brightnessMatrix(_brightness)),
                child: Image.file(File(widget.imagePath), fit: BoxFit.contain),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _tabButton('Recadrer', 0, Icons.crop),
          const SizedBox(width: 8),
          _tabButton('Ajuster', 1, Icons.tune),
        ],
      ),
    );
  }

  Widget _tabButton(String label, int index, IconData icon) {
    final selected = _tab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppTheme.secondaryMain : Colors.white12,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: SafeArea(
        top: false,
        child: _tab == 0 ? _buildCropControls() : _buildAdjustControls(),
      ),
    );
  }

  Widget _buildCropControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Expanded(
          child: Text(
            'Placez les coins sur les bords de l\'œuvre',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
        TextButton.icon(
          onPressed: _resetCorners,
          icon: const Icon(Icons.restart_alt, color: Colors.white),
          label: const Text('Réinit.', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildAdjustControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _slider('Luminosité', _brightness, 0.5, 1.5,
            (v) => setState(() => _brightness = v)),
        _slider('Contraste', _contrast, 0.5, 1.5,
            (v) => setState(() => _contrast = v)),
        _slider('Saturation', _saturation, 0.0, 2.0,
            (v) => setState(() => _saturation = v)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: 'Pivoter à gauche',
              onPressed: () =>
                  setState(() => _quarterTurns = (_quarterTurns + 3) % 4),
              icon: const Icon(Icons.rotate_left, color: Colors.white),
            ),
            const SizedBox(width: 24),
            IconButton(
              tooltip: 'Pivoter à droite',
              onPressed: () =>
                  setState(() => _quarterTurns = (_quarterTurns + 1) % 4),
              icon: const Icon(Icons.rotate_right, color: Colors.white),
            ),
          ],
        ),
      ],
    );
  }

  Widget _slider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(label, style: const TextStyle(color: Colors.white70)),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            activeColor: AppTheme.secondaryMain,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  // --- Color matrices (must mirror the bake math in ImageEditingService). ---

  List<double> _brightnessMatrix(double b) => [
        b, 0, 0, 0, 0, //
        0, b, 0, 0, 0, //
        0, 0, b, 0, 0, //
        0, 0, 0, 1, 0,
      ];

  List<double> _contrastMatrix(double c) {
    final double t = 128 * (1 - c);
    return [
      c, 0, 0, 0, t, //
      0, c, 0, 0, t, //
      0, 0, c, 0, t, //
      0, 0, 0, 1, 0,
    ];
  }

  List<double> _saturationMatrix(double s) {
    const double lr = 0.2126, lg = 0.7152, lb = 0.0722;
    final double sr = (1 - s) * lr;
    final double sg = (1 - s) * lg;
    final double sb = (1 - s) * lb;
    return [
      sr + s, sg, sb, 0, 0, //
      sr, sg + s, sb, 0, 0, //
      sr, sg, sb + s, 0, 0, //
      0, 0, 0, 1, 0,
    ];
  }
}

/// Draws the crop quadrilateral connecting the four corner handles.
class _CropPainter extends CustomPainter {
  final List<Offset> corners; // normalized

  _CropPainter(this.corners);

  @override
  void paint(Canvas canvas, Size size) {
    if (corners.length < 4) return;

    final points = corners
        .map((c) => Offset(c.dx * size.width, c.dy * size.height))
        .toList();

    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    path.close();

    final stroke = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fill = Paint()
      ..color = const Color(0x33000000)
      ..style = PaintingStyle.fill;

    // Dim the area outside the quad.
    final full = Path()..addRect(Offset.zero & size);
    final outside = Path.combine(PathOperation.difference, full, path);
    canvas.drawPath(outside, fill);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(_CropPainter oldDelegate) =>
      oldDelegate.corners != corners;
}
