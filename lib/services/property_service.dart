import 'package:app_envio/models/property.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PropertyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User _requireUser() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }
    return user;
  }

  Future<void> registerProperty({
    required String name,
    required String owner,
    required String addres,
  }) async {
    final user = _requireUser();

    final docRef = _firestore.collection('properties').doc();
    final property = Property(
      id: docRef.id,
      name: name,
      owner: owner,
      userId: user.uid,
      addres: addres,
      createdAt: DateTime.now(),
    );

    await docRef.set(property.toMap());
  }

  Stream<List<Property>> watchMyProperties() {
    final user = _requireUser();

    return _firestore
        .collection('properties')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Property.fromMap(doc.data())).toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
        );
  }

  Future<void> updateProperty({
    required String propertyId,
    required String name,
    required String owner,
    required String addres,
  }) async {
    final user = _requireUser();

    await _firestore.collection('properties').doc(propertyId).update({
      'name': name,
      'owner': owner,
      'addres': addres,
      'userId': user.uid,
    });
  }

  Future<void> deleteProperty(String propertyId) async {
    _requireUser();
    await _firestore.collection('properties').doc(propertyId).delete();
  }
}
