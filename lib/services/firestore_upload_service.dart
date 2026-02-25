import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Serviço para gerenciar metadados de uploads no Firestore, facilitar buscas no painel web
class FirestoreUploadService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Salvar metadados extras após upload bem-sucedido
  Future<void> saveUploadMetadata({
    required String uploadId,
    required String imageUrl,
    double? latitude,
    double? longitude,
    required DateTime uploadedAt,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('Usuário não autenticado');
      }

      await _firestore.collection('uploads').doc(uploadId).set({
        'uploadId': uploadId,
        'userId': userId,
        'userEmail': _auth.currentUser?.email,
        'imageUrl': imageUrl,
        'latitude': latitude,
        'longitude': longitude,
        'uploadedAt': FieldValue.serverTimestamp(),
        'createdAt': uploadedAt.toIso8601String(),
      });
    } catch (e) {
      print('Erro ao salvar metadados de upload: $e');
      rethrow;
    }
  }

  // Obter uploads de usuário no Firestore
  Future<List<Map<String, dynamic>>> getUserUploads() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('Usuário não autenticado');
      }

      final querySnapshot = await _firestore
          .collection('uploads')
          .where('userId', isEqualTo: userId)
          .orderBy('uploadedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => {...doc.data(), 'id': doc.id})
          .toList();
    } catch (e) {
      print('Erro ao obter uploads do usuário: $e');
      return [];
    }
  }

  // Obter todos os uploads (admin)
  Future<List<Map<String, dynamic>>> getAllUploads() async {
    try {
      final querySnapshot = await _firestore
          .collection('uploads')
          .orderBy('uploadedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => {...doc.data(), 'id': doc.id})
          .toList();
    } catch (e) {
      print('Error getting all uploads: $e');
      return [];
    }
  }

  // Obter uploads por intervalo de datas (admin)
  Future<List<Map<String, dynamic>>> getUploadsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('uploads')
          .where('uploadedAt', isGreaterThanOrEqualTo: startDate)
          .where('uploadedAt', isLessThanOrEqualTo: endDate)
          .orderBy('uploadedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => {...doc.data(), 'id': doc.id})
          .toList();
    } catch (e) {
      print('Erro ao obter uploads por intervalo de datas: $e');
      return [];
    }
  }

  // Deletar metadados de upload
  Future<void> deleteUploadMetadata(String uploadId) async {
    try {
      await _firestore.collection('uploads').doc(uploadId).delete();
    } catch (e) {
      print('Error deleting upload metadata: $e');
      rethrow;
    }
  }
}
