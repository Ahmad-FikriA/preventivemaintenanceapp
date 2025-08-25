import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Returns the current user's uid, or null and navigates to /login if not signed in.
String? requireUidOrRedirect(BuildContext context) {
  final u = FirebaseAuth.instance.currentUser;
  if (u == null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) context.go('/login');
    });
    return null;
  }
  return u.uid;
}
