import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class PhotoTile extends StatelessWidget {
  const PhotoTile.network({
    super.key,
    required this.thumbnailUrl,
    required this.onTap,
    this.heroTag,
  }) : localFilePath = null,
       isPending = false,
       isUploading = false,
       errorMessage = null;

  const PhotoTile.local({
    super.key,
    required this.localFilePath,
    required this.onTap,
    required this.isPending,
    required this.isUploading,
    this.errorMessage,
    this.heroTag,
  }) : thumbnailUrl = null;

  final String? thumbnailUrl;
  final String? localFilePath;
  final VoidCallback onTap;
  final bool isPending;
  final bool isUploading;
  final String? errorMessage;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final image = localFilePath != null
        ? Image.file(
            File(localFilePath!),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          )
        : CachedNetworkImage(
            imageUrl: thumbnailUrl!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            placeholder: (context, url) =>
                const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            errorWidget: (context, url, error) =>
                const Center(child: Icon(Icons.broken_image_outlined)),
          );

    final imageChild = heroTag == null
        ? image
        : Hero(tag: heroTag!, child: image);

    return InkWell(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: Theme.of(context).cardColor, child: imageChild),
            if (isPending)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                ),
              ),
            if (isPending)
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: Row(
                  children: [
                    if (isUploading)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      const Icon(Icons.cloud_off, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        isUploading ? 'Syncing...' : (errorMessage ?? 'Queued'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
