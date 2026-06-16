import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Shutter button: a white ring with a brand-blue core when ready to capture,
/// a subtle press animation, and a "scanning" state when disabled.
class CaptureButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isEnabled;

  const CaptureButton({
    super.key,
    required this.onPressed,
    this.isEnabled = true,
  });

  @override
  State<CaptureButton> createState() => _CaptureButtonState();
}

class _CaptureButtonState extends State<CaptureButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.isEnabled;
    return Center(
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTapCancel: enabled ? () => setState(() => _down = false) : null,
        onTap: enabled ? widget.onPressed : null,
        child: AnimatedScale(
          scale: _down ? 0.9 : 1.0,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: enabled ? Colors.white : Colors.white54,
                width: 4,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: enabled
                      ? AppTheme.primaryMain
                      : Colors.white.withOpacity(0.18),
                ),
                child: Icon(
                  enabled ? Icons.camera_alt_rounded : Icons.search,
                  color: enabled ? Colors.white : Colors.white70,
                  size: 30,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
