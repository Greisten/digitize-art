import 'dart:io';
import 'package:flutter/material.dart';
import '../services/scan_storage_service.dart';
import '../theme/app_theme.dart';
import 'edit_screen.dart';

/// Shown right after a capture so the user can keep (save) or discard (retake)
/// the result before it lands in the gallery.
class ReviewScreen extends StatefulWidget {
  final String imagePath;
  final bool isHdr;

  const ReviewScreen({
    super.key,
    required this.imagePath,
    this.isHdr = false,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final ScanStorageService _storage = ScanStorageService();
  bool _isSaving = false;

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await _storage.saveScan(
        sourcePath: widget.imagePath,
        isHdr: widget.isHdr,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save scan: $e'),
            backgroundColor: AppTheme.errorMain,
          ),
        );
      }
    }
  }

  Future<void> _adjust() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditScreen(
          imagePath: widget.imagePath,
          isHdr: widget.isHdr,
        ),
      ),
    );
    // The editor already saved to the gallery; close review too.
    if (saved == true && mounted) Navigator.of(context).pop(true);
  }

  Future<void> _discard() async {
    // Best-effort cleanup of the temporary capture file.
    try {
      final file = File(widget.imagePath);
      if (await file.exists()) await file.delete();
    } catch (_) {}
    if (mounted) Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Review scan'),
        actions: [
          IconButton(
            tooltip: 'Adjust',
            icon: const Icon(Icons.tune),
            onPressed: _isSaving ? null : _adjust,
          ),
          if (widget.isHdr)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Chip(
                label: const Text('HDR'),
                backgroundColor: AppTheme.secondaryMain,
                labelStyle: const TextStyle(color: Colors.white),
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: InteractiveViewer(
                maxScale: 5,
                child: Image.file(
                  File(widget.imagePath),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(Icons.broken_image,
                        color: Colors.white54, size: 64),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isSaving ? null : _discard,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retake'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _save,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check),
                      label: Text(_isSaving ? 'Saving…' : 'Save'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondaryMain,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
