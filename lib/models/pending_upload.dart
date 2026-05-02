class PendingUpload {
  const PendingUpload({
    required this.id,
    required this.albumId,
    required this.localOriginalPath,
    required this.localThumbnailPath,
    required this.createdAt,
    this.isUploading = false,
    this.failureMessage,
  });

  final String id;
  final String albumId;
  final String localOriginalPath;
  final String localThumbnailPath;
  final DateTime createdAt;
  final bool isUploading;
  final String? failureMessage;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'albumId': albumId,
      'localOriginalPath': localOriginalPath,
      'localThumbnailPath': localThumbnailPath,
      'createdAt': createdAt.toIso8601String(),
      'failureMessage': failureMessage,
    };
  }

  factory PendingUpload.fromJson(Map<String, dynamic> json) {
    return PendingUpload(
      id: json['id'] as String,
      albumId: json['albumId'] as String,
      localOriginalPath: json['localOriginalPath'] as String,
      localThumbnailPath: json['localThumbnailPath'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      failureMessage: json['failureMessage'] as String?,
    );
  }

  PendingUpload copyWith({
    bool? isUploading,
    String? failureMessage,
    bool clearFailureMessage = false,
  }) {
    return PendingUpload(
      id: id,
      albumId: albumId,
      localOriginalPath: localOriginalPath,
      localThumbnailPath: localThumbnailPath,
      createdAt: createdAt,
      isUploading: isUploading ?? this.isUploading,
      failureMessage: clearFailureMessage
          ? null
          : failureMessage ?? this.failureMessage,
    );
  }
}
