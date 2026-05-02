import 'package:cloud_firestore/cloud_firestore.dart';

class AlbumPhoto {
  const AlbumPhoto({
    required this.id,
    required this.originalUrl,
    required this.thumbnailUrl,
    required this.timestamp,
  });

  final String id;
  final String originalUrl;
  final String thumbnailUrl;
  final DateTime? timestamp;

  factory AlbumPhoto.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    return AlbumPhoto(
      id: doc.id,
      originalUrl: data['originalUrl'] as String? ?? '',
      thumbnailUrl: data['thumbnailUrl'] as String? ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
    );
  }
}
