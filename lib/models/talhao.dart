class Talhao {
  final String id;
  final String name;
  final String propertyId;
  final String userId;
  final DateTime createdAt;

  const Talhao({
    required this.id,
    required this.name,
    required this.propertyId,
    required this.userId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'propertyId': propertyId,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Talhao.fromMap(Map<String, dynamic> map) {
    return Talhao(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      propertyId: map['propertyId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
