import 'package:flutter/material.dart';

class CaptureButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isEnabled;

  const CaptureButton({
    super.key,
    required this.onPressed,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: isEnabled ? onPressed : null,
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.3),
            border: Border.all(
              color: Colors.white,
              width: 4,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isEnabled ? Colors.white : Colors.grey,
              ),
              child: isEnabled
                  ? const Icon(
                      Icons.camera_alt,
                      color: Colors.black87,
                      size: 32,
                    )
                  : const Icon(
                      Icons.search,
                      color: Colors.black54,
                      size: 32,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
