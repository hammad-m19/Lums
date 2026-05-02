import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/album.dart';
import '../services/album_repository.dart';
import '../services/upload_queue_service.dart';
import '../widgets/album_tile.dart';
import 'album_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.repository,
    required this.uploadQueue,
  });

  final AlbumRepository repository;
  final UploadQueueService uploadQueue;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  bool _isCreatingAlbum = false;

  Future<void> _showCreateAlbumDialog() async {
    final titleController = TextEditingController();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    XFile? selectedImage;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Create album'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(hintText: 'Album title'),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final pickedImage = await _imagePicker.pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 90,
                        );

                        if (pickedImage == null) {
                          return;
                        }

                        setDialogState(() {
                          selectedImage = pickedImage;
                        });
                      },
                      icon: const Icon(Icons.photo_library_outlined),
                      label: Text(
                        selectedImage == null
                            ? 'Pick cover image'
                            : 'Cover selected',
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: _isCreatingAlbum
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: _isCreatingAlbum
                      ? null
                      : () async {
                          final title = titleController.text.trim();
                          if (title.isEmpty || selectedImage == null) {
                            scaffoldMessenger.showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Add a title and pick a cover image.',
                                ),
                              ),
                            );
                            return;
                          }

                          setState(() {
                            _isCreatingAlbum = true;
                          });

                          try {
                            await widget.repository.createAlbum(
                              title: title,
                              coverImage: selectedImage!,
                            );

                            if (!dialogContext.mounted) {
                              return;
                            }
                            Navigator.of(dialogContext).pop();
                          } catch (error) {
                            if (!scaffoldMessenger.mounted) {
                              return;
                            }
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text('Album creation failed: $error'),
                              ),
                            );
                          } finally {
                            if (mounted) {
                              setState(() {
                                _isCreatingAlbum = false;
                              });
                            }
                          }
                        },
                  child: _isCreatingAlbum
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.uploadQueue,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('SnapGather'),
            actions: [
              if (widget.uploadQueue.pendingCount > 0)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Center(
                    child: Text(
                      '${widget.uploadQueue.pendingCount} queued',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _showCreateAlbumDialog,
            child: const Icon(Icons.add),
          ),
          body: StreamBuilder<List<Album>>(
            stream: widget.repository.watchAlbums(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text('Could not load albums.\n${snapshot.error}'),
                );
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final albums = snapshot.data!;
              if (albums.isEmpty) {
                return const Center(
                  child: Text('Create your first album to get started.'),
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _crossAxisCount(constraints.maxWidth),
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.82,
                    ),
                    itemCount: albums.length,
                    itemBuilder: (context, index) {
                      final album = albums[index];
                      return AlbumTile(
                        album: album,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => AlbumScreen(
                                album: album,
                                repository: widget.repository,
                                uploadQueue: widget.uploadQueue,
                              ),
                            ),
                          );
                        },
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
