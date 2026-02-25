import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  // Stream de autenticação
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> registerWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
  }) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      User? user = userCredential.user;

      if (user != null) {
        await user.updateDisplayName(fullName);

        // Salvar dados adicionais no Firestore - Confirmar dados a serem coletados
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'fullName': fullName,
          'phoneNumber': phoneNumber,
          'createdAt': DateTime.now(),
          'updatedAt': DateTime.now(),
        });

        return user;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _translateFirebaseError(e);
    } catch (e) {
      throw 'Erro desconhecido: $e';
    }
  }

  Future<User?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw _translateFirebaseError(e);
    } catch (e) {
      throw 'Erro desconhecido: $e';
    }
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print(e);
      throw 'Erro ao fazer logout: $e';
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _translateFirebaseError(e);
    } catch (e) {
      throw 'Erro desconhecido: $e';
    }
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      throw 'Erro ao obter dados do usuário: $e';
    }
  }

  Future<void> updateUserData({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        ...data,
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      throw 'Erro ao atualizar dados do usuário: $e';
    }
  }

  Future<void> updateCurrentUserProfile({
    required String fullName,
    required String phoneNumber,
  }) async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        throw 'Usuário não autenticado.';
      }

      await user.updateDisplayName(fullName);

      await updateUserData(
        uid: user.uid,
        data: {'fullName': fullName, 'phoneNumber': phoneNumber},
      );

      await user.reload();
    } catch (e) {
      throw 'Erro ao atualizar perfil: $e';
    }
  }

  // Tratamento de exceções do Firebase Auth
  String _translateFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'A senha é muito fraca. Use uma senha mais forte.';
      case 'email-already-in-use':
        return 'Este email já está cadastrado.';
      case 'invalid-email':
        return 'O email fornecido é inválido.';
      case 'user-disabled':
        return 'Esta conta de usuário foi desativada.';
      case 'user-not-found':
        return 'Usuário não encontrado.';
      case 'wrong-password':
        return 'Senha incorreta.';
      case 'operation-not-allowed':
        return 'Esta operação não é permitida.';
      case 'too-many-requests':
        return 'Muitas tentativas de login. Tente novamente mais tarde.';
      case 'invalid-credential':
        return 'Email ou senha inválidos.';
      default:
        return 'Erro de autenticação: ${e.message}';
    }
  }
}
