import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/album.dart';
import '../models/album_photo.dart';
import '../services/album_repository.dart';
import '../services/upload_queue_service.dart';
import '../widgets/photo_tile.dart';

class AlbumScreen extends StatefulWidget {
  const AlbumScreen({
    super.key,
    required this.album,
    required this.repository,
    required this.uploadQueue,
  });

  final Album album;
  final AlbumRepository repository;
  final UploadQueueService uploadQueue;

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> _capturePhoto() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 95,
      );

      if (image == null) {
        return;
      }

      await widget.uploadQueue.enqueueCameraPhoto(
        albumId: widget.album.id,
        image: image,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Photo saved. It will upload immediately or stay queued offline.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not capture photo: $error')),
      );
    }
  }

  int _crossAxisCount(double width) {
    if (width >= 1200) {
      return 5;
    }
    if (width >= 900) {
      return 4;
    }
    if (width >= 600) {
      return 3;
    }
    return 2;
  }

  void _openViewer({
    required ImageProvider imageProvider,
    required String heroTag,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            _PhotoViewerScreen(imageProvider: imageProvider, heroTag: heroTag),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.uploadQueue,
      builder: (context, _) {
        final pendingUploads = widget.uploadQueue.pendingForAlbum(
          widget.album.id,
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.album.title),
            actions: [
              if (pendingUploads.isNotEmpty)
                IconButton(
                  onPressed: widget.uploadQueue.retryNow,
                  icon: const Icon(Icons.sync),
                  tooltip: 'Retry uploads',
                ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _capturePhoto,
            child: const Icon(Icons.camera_alt_outlined),
          ),
          body: StreamBuilder<List<AlbumPhoto>>(
            stream: widget.repository.watchPhotos(widget.album.id),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text('Could not load photos.\n${snapshot.error}'),
                );
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final photos = snapshot.data!;
              if (photos.isEmpty && pendingUploads.isEmpty) {
                return const Center(
                  child: Text('Use the camera button to add the first photo.'),
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _crossAxisCount(constraints.maxWidth),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                    ),
                    itemCount: pendingUploads.length + photos.length,
                    itemBuilder: (context, index) {
                      if (index < pendingUploads.length) {
                        final upload = pendingUploads[index];
                        final heroTag = 'pending-${upload.id}';

                        return PhotoTile.local(
                          localFilePath: upload.localThumbnailPath,
                          heroTag: heroTag,
                          isPending: true,
                          isUploading: upload.isUploading,
                          errorMessage: upload.failureMessage,
                          onTap: () => _openViewer(
                            imageProvider: FileImage(
                              File(upload.localOriginalPath),
                            ),
                            heroTag: heroTag,
                          ),
                        );
                      }

                      final photo = photos[index - pendingUploads.length];
                      final heroTag = 'remote-${photo.id}';

                      return PhotoTile.network(
                        thumbnailUrl: photo.thumbnailUrl,
                        heroTag: heroTag,
                        onTap: () => _openViewer(
                          imageProvider: CachedNetworkImageProvider(
                            photo.originalUrl,
                          ),
                          heroTag: heroTag,
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _PhotoViewerScreen extends StatelessWidget {
  const _PhotoViewerScreen({
    required this.imageProvider,
    required this.heroTag,
  });

  final ImageProvider imageProvider;
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 4,
          child: Hero(
            tag: heroTag,
            child: Image(image: imageProvider, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
