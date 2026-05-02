import 'package:cloud_firestore/cloud_firestore.dart';

class Album {
  const Album({
    required this.id,
    required this.title,
    required this.coverImageUrl,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String coverImageUrl;
  final DateTime? createdAt;

  factory Album.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    return Album(
      id: doc.id,
      title: (data['title'] as String?)?.trim() ?? 'Untitled',
      coverImageUrl: data['coverImageUrl'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
