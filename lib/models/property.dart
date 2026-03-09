class Property {
  final String id;
  final String name;
  final String owner;
  final String userId;
  final String addres;
  final DateTime createdAt;

  const Property({
    required this.id,
    required this.name,
    required this.owner,
    required this.userId,
    required this.addres,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'owner': owner,
      'userId': userId,
      'addres': addres,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Property.fromMap(Map<String, dynamic> map) {
    return Property(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      owner: map['owner'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      addres: map['addres'] as String? ?? '',
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
