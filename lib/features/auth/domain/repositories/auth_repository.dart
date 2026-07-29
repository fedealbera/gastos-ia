import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

abstract class AuthRepository {
  Future<firebase_auth.User?> signInWithGoogle();
  Future<void> signOut();
  Stream<firebase_auth.User?> get authStateChanges;
  firebase_auth.User? get currentUser;
}
