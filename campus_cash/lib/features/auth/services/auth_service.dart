import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserModel?> getCurrentUserProfile() async {
    final user = currentUser;
    if (user == null) return null;
    return getUserProfile(user.uid);
  }

  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Stream<UserModel?> streamUserProfile(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  Future<UserCredential> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = cred.user;
    if (user != null) {
      await user.sendEmailVerification();
      await user.updateDisplayName(name);

      final userModel = UserModel(
        userId: user.uid,
        name: name,
        email: email.trim(),
        completedExchanges: 0,
        rating: 5.0,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(user.uid).set(userModel.toMap());
    }

    return cred;
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> signInWithGoogle() async {
    final GoogleAuthProvider googleProvider = GoogleAuthProvider();
    googleProvider.addScope('email');
    googleProvider.addScope('profile');

    UserCredential cred;
    if (kIsWeb) {
      cred = await _auth.signInWithPopup(googleProvider);
    } else {
      cred = await _auth.signInWithProvider(googleProvider);
    }

    final user = cred.user;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        final userModel = UserModel(
          userId: user.uid,
          name: user.displayName ?? (user.email?.split('@').first ?? 'CashMate User'),
          email: user.email ?? '',
          completedExchanges: 0,
          rating: 5.0,
          isActive: true,
          createdAt: DateTime.now(),
        );

        await _firestore.collection('users').doc(user.uid).set(userModel.toMap());
      }
    }

    return cred;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> updateUserProfile(UserModel updatedUser) async {
    final user = _auth.currentUser;
    if (user != null && updatedUser.name.isNotEmpty && user.displayName != updatedUser.name) {
      await user.updateDisplayName(updatedUser.name.trim());
    }
    await _firestore
        .collection('users')
        .doc(updatedUser.userId)
        .update(updatedUser.toMap());
  }

  Future<void> updateNotificationPreferences(
    String uid,
    Map<String, bool> preferences,
  ) async {
    await _firestore.collection('users').doc(uid).update({
      'notificationPreferences': preferences,
    });
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
