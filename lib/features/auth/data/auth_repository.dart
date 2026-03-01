import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import '../domain/models/user_model.dart';
import '../../../core/errors/failure.dart';

class AuthRepository {
  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentFirebaseUser => _auth.currentUser;

  // ── Sign in / Sign up ──────────────────────────────────────────────────────

  Future<UserModel> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return _fetchOrCreateUser(credential.user!);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapFirebaseError(e.code));
    }
  }

  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await credential.user!.updateDisplayName(displayName.trim());
      return _createUserDocument(
        uid: credential.user!.uid,
        email: email.trim(),
        displayName: displayName.trim(),
        photoUrl: null,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapFirebaseError(e.code));
    }
  }

  Future<UserModel> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // On web, use Firebase Auth's signInWithPopup — avoids the deprecated
        // google_sign_in signIn() that can't reliably return an idToken on web.
        final userCredential =
            await _auth.signInWithPopup(GoogleAuthProvider());
        return _fetchOrCreateUser(userCredential.user!);
      }
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw const AuthFailure('Sign-in cancelled');
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      return _fetchOrCreateUser(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapFirebaseError(e.code));
    } on AuthFailure {
      rethrow;
    } catch (_) {
      throw const AuthFailure('Google sign-in failed. Please try again.');
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapFirebaseError(e.code));
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Google session may not exist (e.g. email/password users on web)
    }
  }

  // ── User document ──────────────────────────────────────────────────────────

  Future<UserModel?> getCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;
    final doc =
        await _firestore.collection('users').doc(firebaseUser.uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!, doc.id);
  }

  Stream<UserModel?> watchCurrentUser() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(null);
    return _firestore.collection('users').doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return UserModel.fromMap(snap.data()!, snap.id);
    });
  }

  Future<void> updateUser(UserModel user) async {
    await _firestore
        .collection('users')
        .doc(user.uid)
        .update({...user.toMap(), 'updatedAt': DateTime.now().toIso8601String()});
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<UserModel> _fetchOrCreateUser(User firebaseUser) async {
    final doc =
        await _firestore.collection('users').doc(firebaseUser.uid).get();
    if (doc.exists) return UserModel.fromMap(doc.data()!, doc.id);
    return _createUserDocument(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName ?? '',
      photoUrl: firebaseUser.photoURL,
    );
  }

  Future<UserModel> _createUserDocument({
    required String uid,
    required String email,
    required String displayName,
    String? photoUrl,
  }) async {
    final now = DateTime.now();
    final user = UserModel(
      uid: uid,
      displayName: displayName,
      email: email,
      photoUrl: photoUrl,
      createdAt: now,
      updatedAt: now,
    );
    await _firestore.collection('users').doc(uid).set(user.toMap());
    return user;
  }

  String _mapFirebaseError(String code) => switch (code) {
        'user-not-found' => 'No account found with this email.',
        'wrong-password' || 'invalid-credential' =>
          'Incorrect email or password.',
        'email-already-in-use' =>
          'An account with this email already exists.',
        'weak-password' => 'Password is too weak.',
        'invalid-email' => 'Invalid email address.',
        'user-disabled' => 'This account has been disabled.',
        'too-many-requests' =>
          'Too many attempts. Please try again later.',
        'network-request-failed' =>
          'Network error. Check your connection.',
        _ => 'Authentication failed. Please try again.',
      };
}
