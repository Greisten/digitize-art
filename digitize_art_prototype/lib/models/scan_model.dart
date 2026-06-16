/// A single saved artwork scan stored on the device.
class ScanModel {
  /// Unique id (millisecond timestamp string at creation).
  final String id;

  /// Absolute path to the saved image file in app storage.
  final String filePath;

  /// When the scan was saved.
  final DateTime createdAt;

  /// Whether the scan was produced by the HDR multi-shot pipeline.
  final bool isHdr;

  /// Optional user-provided title.
  final String? title;

  ScanModel({
    required this.id,
    required this.filePath,
    required this.createdAt,
    this.isHdr = false,
    this.title,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'filePath': filePath,
        'createdAt': createdAt.toIso8601String(),
        'isHdr': isHdr,
        'title': title,
      };

  factory ScanModel.fromJson(Map<String, dynamic> json) => ScanModel(
        id: json['id'] as String,
        filePath: json['filePath'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        isHdr: json['isHdr'] as bool? ?? false,
        title: json['title'] as String?,
      );

  ScanModel copyWith({String? title}) => ScanModel(
        id: id,
        filePath: filePath,
        createdAt: createdAt,
        isHdr: isHdr,
        title: title ?? this.title,
      );
}
