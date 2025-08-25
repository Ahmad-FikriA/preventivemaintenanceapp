import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> signIn(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
      final uid = cred.user!.uid;

      final userDoc = await _db.collection('users').doc(uid).get();
      final data = userDoc.data() ?? {};
      final role = (data['role'] as String?) ?? 'user';

      return {
        'user': cred.user,
        'userData': {...data, 'role': role},
      };
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e));
    }
  }

  Future<User> register({
    required String email,
    required String password,
    required String name,
    required String role,
    String? phone,
    String? department,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = cred.user!.uid;

      await _db.collection('users').doc(uid).set({
        'name': name,
        'email': email.trim(),
        'role': role, // 'technician' | 'supervisor' | 'admin'
        'phone': phone ?? '',
        'department': department ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return cred.user!;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e));
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e));
    }
  }

  Future<void> signOut() => _auth.signOut();

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email': return 'Email tidak valid';
      case 'user-disabled': return 'Akun dinonaktifkan';
      case 'user-not-found': return 'Akun tidak ditemukan';
      case 'wrong-password': return 'Password salah';
      case 'email-already-in-use': return 'Email sudah terdaftar';
      case 'weak-password': return 'Password terlalu lemah';
      case 'operation-not-allowed': return 'Operasi tidak diizinkan';
      default: return 'Autentikasi gagal: ${e.message ?? e.code}';
    }
  }
}
