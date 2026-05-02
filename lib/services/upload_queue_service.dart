import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/pending_upload.dart';
import 'album_repository.dart';
import 'image_processing_service.dart';

class UploadQueueService extends ChangeNotifier {
  UploadQueueService({
    required AlbumRepository repository,
    ImageProcessingService? imageProcessingService,
  }) : _repository = repository,
       _imageProcessingService =
           imageProcessingService ?? ImageProcessingService();

  final AlbumRepository _repository;
  final ImageProcessingService _imageProcessingService;
  final Uuid _uuid = const Uuid();

  final List<PendingUpload> _pendingUploads = [];
  Timer? _retryTimer;
  bool _isProcessing = false;

  List<PendingUpload> get pendingUploads => List.unmodifiable(_pendingUploads);

  int get pendingCount => _pendingUploads.length;

  List<PendingUpload> pendingForAlbum(String albumId) {
    return _pendingUploads
        .where((upload) => upload.albumId == albumId)
        .toList(growable: false)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> initialize() async {
    _pendingUploads
      ..clear()
      ..addAll(await _readQueueFile());
    notifyListeners();

    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => unawaited(processPendingUploads()),
    );

    await processPendingUploads();
  }

  Future<void> enqueueCameraPhoto({
    required String albumId,
    required XFile image,
  }) async {
    final photoId = _uuid.v4();
    final original = await _imageProcessingService.createOriginal(
      image,
      prefix: 'original-$photoId',
    );
    final thumbnail = await _imageProcessingService.createThumbnail(image);
    final queueDir = await _queueDirectory();

    final originalCopy = await original.copy(
      '${queueDir.path}/$photoId-original.jpg',
    );
    final thumbnailCopy = await thumbnail.copy(
      '${queueDir.path}/$photoId-thumbnail.jpg',
    );

    final item = PendingUpload(
      id: photoId,
      albumId: albumId,
      localOriginalPath: originalCopy.path,
      localThumbnailPath: thumbnailCopy.path,
      createdAt: DateTime.now(),
    );

    _pendingUploads.insert(0, item);
    await _persistQueue();
    notifyListeners();

    unawaited(processPendingUploads());
  }

  Future<void> processPendingUploads() async {
    if (_isProcessing || _pendingUploads.isEmpty) {
      return;
    }

    _isProcessing = true;

    try {
      for (final upload in List<PendingUpload>.from(_pendingUploads)) {
        await _setUploading(upload.id, true, clearError: true);

        try {
          await _repository.uploadAlbumPhoto(
            albumId: upload.albumId,
            photoId: upload.id,
            originalFile: File(upload.localOriginalPath),
            thumbnailFile: File(upload.localThumbnailPath),
            createdAt: upload.createdAt,
          );

          await _cleanupFiles(upload);
          _pendingUploads.removeWhere((item) => item.id == upload.id);
          await _persistQueue();
          notifyListeners();
        } catch (error) {
          await _setUploading(
            upload.id,
            false,
            errorMessage: 'Waiting for network to finish upload.',
          );
          break;
        }
      }
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> retryNow() => processPendingUploads();

  Future<void> _setUploading(
    String id,
    bool isUploading, {
    String? errorMessage,
    bool clearError = false,
  }) async {
    final index = _pendingUploads.indexWhere((item) => item.id == id);
    if (index == -1) {
      return;
    }

    _pendingUploads[index] = _pendingUploads[index].copyWith(
      isUploading: isUploading,
      failureMessage: errorMessage,
      clearFailureMessage: clearError,
    );
    await _persistQueue();
    notifyListeners();
  }

  Future<void> _cleanupFiles(PendingUpload upload) async {
    final original = File(upload.localOriginalPath);
    final thumbnail = File(upload.localThumbnailPath);

    if (await original.exists()) {
      await original.delete();
    }
    if (await thumbnail.exists()) {
      await thumbnail.delete();
    }
  }

  Future<List<PendingUpload>> _readQueueFile() async {
    final queueFile = await _queueFile();
    if (!await queueFile.exists()) {
      return <PendingUpload>[];
    }

    final rawJson = await queueFile.readAsString();
    if (rawJson.trim().isEmpty) {
      return <PendingUpload>[];
    }

    final decoded = jsonDecode(rawJson) as List<dynamic>;
    return decoded
        .map((item) => PendingUpload.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<void> _persistQueue() async {
    final queueFile = await _queueFile();
    final payload = _pendingUploads
        .map((upload) => upload.toJson())
        .toList(growable: false);
    await queueFile.writeAsString(jsonEncode(payload));
  }

  Future<Directory> _queueDirectory() async {
    final root = await getApplicationDocumentsDirectory();
    final queueDir = Directory('${root.path}/upload_queue');

    if (!await queueDir.exists()) {
      await queueDir.create(recursive: true);
    }

    return queueDir;
  }

  Future<File> _queueFile() async {
    final dir = await _queueDirectory();
    return File('${dir.path}/pending_uploads.json');
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }
}
