import 'dart:io';
import 'package:flutter/material.dart';
import '../models/scan_model.dart';
import '../services/scan_storage_service.dart';
import '../theme/app_theme.dart';

/// Grid of saved scans. Tap a scan to view it full-screen; delete from there.
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final ScanStorageService _storage = ScanStorageService();
  late Future<List<ScanModel>> _scansFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _scansFuture = _storage.loadScans();
  }

  Future<void> _openScan(ScanModel scan) async {
    final deleted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => _ScanViewer(scan: scan)),
    );
    if (deleted == true && mounted) {
      setState(_reload);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('My scans'),
      ),
      body: FutureBuilder<List<ScanModel>>(
        future: _scansFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          final scans = snapshot.data ?? const [];
          if (scans.isEmpty) {
            return const _EmptyGallery();
          }

          return RefreshIndicator(
            onRefresh: () async => setState(_reload),
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: scans.length,
              itemBuilder: (context, index) {
                final scan = scans[index];
                return GestureDetector(
                  onTap: () => _openScan(scan),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(
                          File(scan.filePath),
                          fit: BoxFit.cover,
                          cacheWidth: 300,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            color: Colors.white12,
                            child: const Icon(Icons.broken_image,
                                color: Colors.white38),
                          ),
                        ),
                        if (scan.isHdr)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.secondaryMain,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'HDR',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _EmptyGallery extends StatelessWidget {
  const _EmptyGallery();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.photo_library_outlined, color: Colors.white38, size: 72),
          SizedBox(height: 16),
          Text(
            'No scans yet',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          SizedBox(height: 8),
          Text(
            'Capture an artwork to see it here.',
            style: TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }
}

/// Full-screen view of a single scan with a delete action.
class _ScanViewer extends StatelessWidget {
  final ScanModel scan;

  const _ScanViewer({required this.scan});

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete scan?'),
        content: const Text('This permanently removes the scan from your device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorMain),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ScanStorageService().deleteScan(scan.id);
      if (context.mounted) Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(scan.title ?? 'Scan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete',
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          maxScale: 5,
          child: Image.file(
            File(scan.filePath),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Center(
              child: Icon(Icons.broken_image, color: Colors.white54, size: 64),
            ),
          ),
        ),
      ),
    );
  }
}
