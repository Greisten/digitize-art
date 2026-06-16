import 'dart:io';
import 'package:flutter/material.dart';
import '../services/scan_storage_service.dart';
import '../theme/app_theme.dart';
import 'edit_screen.dart';

/// Shown right after a capture so the user can keep (save), retake, or adjust
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
      await _storage.saveScan(sourcePath: widget.imagePath, isHdr: widget.isHdr);
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

  Future<void> _adjust() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            EditScreen(imagePath: widget.imagePath, isHdr: widget.isHdr),
      ),
    );
    if (saved == true && mounted) Navigator.of(context).pop(true);
  }

  Future<void> _discard() async {
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
        title: const Text('Aperçu'),
        actions: [
          if (widget.isHdr)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 14),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.brandYellow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'HDR',
                style: TextStyle(
                  color: AppTheme.brandBlack,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: InteractiveViewer(
                  maxScale: 5,
                  child: Center(
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
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Column(
                children: [
                  // Adjust (secondary, full width).
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: _isSaving ? null : _adjust,
                      icon: const Icon(Icons.tune, color: Colors.white),
                      label: const Text('Ajuster (recadrer, lumière…)',
                          style: TextStyle(color: Colors.white)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.white.withOpacity(0.08),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isSaving ? null : _discard,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refaire'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
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
                          label: Text(_isSaving ? 'Enregistre…' : 'Enregistrer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryMain,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
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
