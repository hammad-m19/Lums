import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class ImageProcessingService {
  Future<File> createAlbumCover(XFile source) async {
    return _compressXFile(source, minWidth: 1200, quality: 72, prefix: 'cover');
  }

  Future<File> createOriginal(
    XFile source, {
    String prefix = 'original',
  }) async {
    return _compressXFile(source, minWidth: 1600, quality: 78, prefix: prefix);
  }

  Future<File> createThumbnail(XFile source) async {
    return _compressXFile(source, minWidth: 300, quality: 20, prefix: 'thumb');
  }

  Future<File> _compressXFile(
    XFile source, {
    required int minWidth,
    required int quality,
    required String prefix,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final targetPath =
        '${tempDir.path}/$prefix-${DateTime.now().microsecondsSinceEpoch}.jpg';

    final compressed = await FlutterImageCompress.compressAndGetFile(
      source.path,
      targetPath,
      format: CompressFormat.jpeg,
      quality: quality,
      minWidth: minWidth,
      keepExif: false,
    );

    final outputPath = compressed?.path ?? source.path;
    return File(outputPath);
  }
}
