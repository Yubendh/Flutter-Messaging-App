import 'package:cloud_firestore/cloud_firestore.dart';

class ResourceItem {
  final String id;
  final String type;
  final String title;
  final String url;
  final String uploadedBy;
  final String uploadedByName;
  final DateTime uploadedAt;

  final String? fileName;
  final int? fileSize;
  final String? storagePath;

  const ResourceItem({
    required this.id,
    required this.type,
    required this.title,
    required this.url,
    required this.uploadedBy,
    required this.uploadedByName,
    required this.uploadedAt,
    this.fileName,
    this.fileSize,
    this.storagePath,
  });

  factory ResourceItem.fromFirestore(String id, Map<String, dynamic> data) {
    return ResourceItem(
      id: id,
      type: data['type'] as String? ?? 'link',
      title: data['title'] as String? ?? '',
      url: data['url'] as String? ?? '',
      uploadedBy: data['uploadedBy'] as String? ?? '',
      uploadedByName: data['uploadedByName'] as String? ?? '',
      uploadedAt: data['uploadedAt'] != null
          ? (data['uploadedAt'] as Timestamp).toDate()
          : DateTime.now(),
      fileName: data['fileName'] as String?,
      fileSize: data['fileSize'] as int?,
      storagePath: data['storagePath'] as String?,
    );
  }
}
