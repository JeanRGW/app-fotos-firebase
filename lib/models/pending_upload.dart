class PendingUpload {
  final String id;
  final String imagePath;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;
  final UploadStatus status;
  final String? errorMessage;
  final String? firebaseUrl;

  PendingUpload({
    required this.id,
    required this.imagePath,
    this.latitude,
    this.longitude,
    required this.createdAt,
    required this.status,
    this.errorMessage,
    this.firebaseUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'image_path': imagePath,
      'latitude': latitude,
      'longitude': longitude,
      'created_at': createdAt.millisecondsSinceEpoch,
      'status': status.name,
      'error_message': errorMessage,
      'firebase_url': firebaseUrl,
    };
  }

  factory PendingUpload.fromMap(Map<String, dynamic> map) {
    return PendingUpload(
      id: map['id'] as String,
      imagePath: map['image_path'] as String,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      status: UploadStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => UploadStatus.pending,
      ),
      errorMessage: map['error_message'] as String?,
      firebaseUrl: map['firebase_url'] as String?,
    );
  }

  PendingUpload copyWith({
    String? id,
    String? imagePath,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    UploadStatus? status,
    String? errorMessage,
    String? firebaseUrl,
  }) {
    return PendingUpload(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      firebaseUrl: firebaseUrl ?? this.firebaseUrl,
    );
  }
}

enum UploadStatus { pending, uploading, completed, failed }
