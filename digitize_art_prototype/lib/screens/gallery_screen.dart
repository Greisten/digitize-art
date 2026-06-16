import 'dart:io';
import 'package:flutter/material.dart';
import '../models/scan_model.dart';
import '../services/scan_storage_service.dart';
import '../theme/app_theme.dart';

/// "Gallery wall" of saved scans on a clean light surface. Tap a scan to view
/// it full-screen; delete from there.
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
      backgroundColor: AppTheme.brandWhite,
      body: SafeArea(
        child: FutureBuilder<List<ScanModel>>(
          future: _scansFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryMain),
              );
            }

            final scans = snapshot.data ?? const [];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(scans.length),
                Expanded(
                  child: scans.isEmpty
                      ? const _EmptyGallery()
                      : RefreshIndicator(
                          color: AppTheme.primaryMain,
                          onRefresh: () async => setState(_reload),
                          child: GridView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.82,
                            ),
                            itemCount: scans.length,
                            itemBuilder: (context, index) =>
                                _buildTile(scans[index]),
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 16),
      child: Row(
        children: [
          // Brand accent bar (blue / red / yellow).
          Container(
            width: 6,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.brandBlue,
                  AppTheme.brandRed,
                  AppTheme.brandYellow,
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mes scans',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.brandBlack,
                  ),
                ),
                Text(
                  count == 0
                      ? 'Aucun scan'
                      : '$count ${count > 1 ? 'œuvres' : 'œuvre'}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF8A8A8A),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppTheme.brandBlack),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(ScanModel scan) {
    return GestureDetector(
      onTap: () => _openScan(scan),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x11000000)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(scan.filePath),
              fit: BoxFit.cover,
              cacheWidth: 400,
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Icon(Icons.broken_image, color: Color(0xFFBBBBBB)),
              ),
            ),
            if (scan.isHdr)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.brandYellow,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'HDR',
                    style: TextStyle(
                      color: AppTheme.brandBlack,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
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
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: AppTheme.brandBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.photo_library_outlined,
              color: AppTheme.brandBlue,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Pas encore de scan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.brandBlack,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Numérisez une œuvre pour la retrouver ici.',
            style: TextStyle(color: Color(0xFF8A8A8A)),
          ),
        ],
      ),
    );
  }
}

/// Full-screen view of a single scan with a delete action (dark for contrast).
class _ScanViewer extends StatelessWidget {
  final ScanModel scan;

  const _ScanViewer({required this.scan});

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le scan ?'),
        content: const Text('Cette action retire définitivement le scan de votre appareil.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorMain),
            child: const Text('Supprimer'),
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
            tooltip: 'Supprimer',
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
