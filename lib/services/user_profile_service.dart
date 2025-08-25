import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfileService {
  final _db = FirebaseFirestore.instance;

  /// Ensure users/{uid} exists and has searchable fields.
  /// Does NOT overwrite role if it's already set.
  Future<void> ensureUserDoc(User user) async {
    final ref = _db.collection('users').doc(user.uid);
    final snap = await ref.get();

    final data = <String, dynamic>{
      'email': user.email ?? '',
      'emailLower': (user.email ?? '').toLowerCase(),
      'name': user.displayName ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (!snap.exists) {
      // First time — default role 'user' (you can change to 'admin' manually in console for yourself)
      data['role'] = 'user';
      await ref.set(data, SetOptions(merge: true));
    } else {
      // Existing — keep current role value
      await ref.set(data, SetOptions(merge: true));
    }
  }
}
