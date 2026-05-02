import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../models/album.dart';
import '../models/album_photo.dart';
import 'image_processing_service.dart';

class AlbumRepository {
  AlbumRepository({
    required ImageProcessingService imageProcessingService,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _imageProcessingService = imageProcessingService,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  final ImageProcessingService _imageProcessingService;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  Stream<List<Album>> watchAlbums() {
    return _firestore
        .collection('albums')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(Album.fromDocument).toList(growable: false),
        );
  }

  Stream<List<AlbumPhoto>> watchPhotos(String albumId) {
    return _firestore
        .collection('albums')
        .doc(albumId)
        .collection('photos')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(AlbumPhoto.fromDocument)
              .toList(growable: false),
        );
  }

  Future<void> createAlbum({
    required String title,
    required XFile coverImage,
  }) async {
    final albumRef = _firestore.collection('albums').doc();
    final coverFile = await _imageProcessingService.createAlbumCover(
      coverImage,
    );
    final storageRef = _storage.ref(
      'albums/${albumRef.id}/cover/${albumRef.id}.jpg',
    );

    await storageRef.putFile(
      coverFile,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    final coverImageUrl = await storageRef.getDownloadURL();

    await albumRef.set({
      'title': title.trim(),
      'coverImageUrl': coverImageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> uploadAlbumPhoto({
    required String albumId,
    required String photoId,
    required File originalFile,
    required File thumbnailFile,
    required DateTime createdAt,
  }) async {
    final originalsRef = _storage.ref('albums/$albumId/originals/$photoId.jpg');
    final thumbnailsRef = _storage.ref(
      'albums/$albumId/thumbnails/$photoId.jpg',
    );

    await thumbnailsRef.putFile(
      thumbnailFile,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    await originalsRef.putFile(
      originalFile,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    final thumbnailUrl = await thumbnailsRef.getDownloadURL();
    final originalUrl = await originalsRef.getDownloadURL();

    await _firestore
        .collection('albums')
        .doc(albumId)
        .collection('photos')
        .doc(photoId)
        .set({
          'thumbnailUrl': thumbnailUrl,
          'originalUrl': originalUrl,
          'timestamp': Timestamp.fromDate(createdAt),
        });
  }
}
