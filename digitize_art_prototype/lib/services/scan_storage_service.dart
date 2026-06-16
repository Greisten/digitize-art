import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/scan_model.dart';

/// Local, dependency-free persistence for saved scans.
///
/// Image files live in `<appDocuments>/scans/` and the metadata is kept in a
/// small `index.json` alongside them. This avoids pulling in a database
/// dependency while still surviving app restarts.
class ScanStorageService {
  static const String _scansDirName = 'scans';
  static const String _indexFileName = 'index.json';

  Future<Directory> _scansDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, _scansDirName));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<File> _indexFile() async {
    final dir = await _scansDir();
    return File(p.join(dir.path, _indexFileName));
  }

  /// Load all saved scans, newest first. Returns an empty list on any error.
  Future<List<ScanModel>> loadScans() async {
    try {
      final file = await _indexFile();
      if (!await file.exists()) return [];

      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! List) return [];

      final scans = decoded
          .whereType<Map<String, dynamic>>()
          .map(ScanModel.fromJson)
          .toList();
      scans.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return scans;
    } catch (_) {
      return [];
    }
  }

  Future<void> _writeIndex(List<ScanModel> scans) async {
    final file = await _indexFile();
    await file.writeAsString(
      jsonEncode(scans.map((s) => s.toJson()).toList()),
    );
  }

  /// Copy the image at [sourcePath] into persistent storage and record it.
  Future<ScanModel> saveScan({
    required String sourcePath,
    bool isHdr = false,
    String? title,
  }) async {
    final dir = await _scansDir();
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final ext = p.extension(sourcePath).isEmpty ? '.jpg' : p.extension(sourcePath);
    final destPath = p.join(dir.path, 'scan_$id$ext');

    await File(sourcePath).copy(destPath);

    final scan = ScanModel(
      id: id,
      filePath: destPath,
      createdAt: DateTime.now(),
      isHdr: isHdr,
      title: title,
    );

    final scans = await loadScans();
    scans.insert(0, scan);
    await _writeIndex(scans);

    return scan;
  }

  /// Delete a scan (its file and metadata entry).
  Future<void> deleteScan(String id) async {
    final scans = await loadScans();
    final index = scans.indexWhere((s) => s.id == id);
    if (index < 0) return;

    final scan = scans.removeAt(index);
    try {
      final file = File(scan.filePath);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Ignore file-system errors; still drop the metadata entry.
    }
    await _writeIndex(scans);
  }

  /// Rename a scan's title.
  Future<void> renameScan(String id, String title) async {
    final scans = await loadScans();
    final index = scans.indexWhere((s) => s.id == id);
    if (index < 0) return;
    scans[index] = scans[index].copyWith(title: title);
    await _writeIndex(scans);
  }
}
