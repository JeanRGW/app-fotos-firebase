import 'package:app_envio/models/talhao.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TalhaoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User _requireUser() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }
    return user;
  }

  Future<void> _ensurePropertyExists({
    required String propertyId,
    required String userId,
  }) async {
    final propertyDoc = await _firestore
        .collection('properties')
        .doc(propertyId)
        .get();

    if (!propertyDoc.exists) {
      throw Exception('Propriedade não encontrada.');
    }

    final data = propertyDoc.data();
    if (data == null || data['userId'] != userId) {
      throw Exception('Você não tem acesso a esta propriedade.');
    }
  }

  Future<void> registerTalhao({
    required String name,
    required String propertyId,
  }) async {
    final user = _requireUser();
    await _ensurePropertyExists(propertyId: propertyId, userId: user.uid);

    final docRef = _firestore.collection('talhoes').doc();
    final talhao = Talhao(
      id: docRef.id,
      name: name,
      propertyId: propertyId,
      userId: user.uid,
      createdAt: DateTime.now(),
    );

    await docRef.set(talhao.toMap());
  }

  Stream<List<Talhao>> watchTalhoesByProperty(String propertyId) {
    final user = _requireUser();

    return _firestore
        .collection('talhoes')
        .where('userId', isEqualTo: user.uid)
        .where('propertyId', isEqualTo: propertyId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Talhao.fromMap(doc.data())).toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
        );
  }

  Future<void> updateTalhao({
    required String talhaoId,
    required String name,
    required String propertyId,
  }) async {
    final user = _requireUser();

    await _firestore.collection('talhoes').doc(talhaoId).update({
      'name': name,
      'propertyId': propertyId,
      'userId': user.uid,
    });
  }

  Future<void> deleteTalhao(String talhaoId) async {
    _requireUser();
    await _firestore.collection('talhoes').doc(talhaoId).delete();
  }
}
