// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../utils/constants.dart';

class AuthService {
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser != null
      ? User(
          id: _auth.currentUser!.uid,
          email: _auth.currentUser!.email ?? '',
          name: _auth.currentUser!.displayName ?? '',
          phone: _auth.currentUser!.phoneNumber ?? '',
          role: 'customer',
          createdAt: DateTime.now(),
        )
      : null;

  // Stream of auth state changes
  Stream<User?> get authStateChanges {
    return _auth.authStateChanges().map((firebaseUser) {
      if (firebaseUser != null) {
        return User(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          name: firebaseUser.displayName ?? '',
          phone: firebaseUser.phoneNumber ?? '',
          role: 'customer',
          createdAt: DateTime.now(),
        );
      }
      return null;
    });
  }

  // Login with email and password
  Future<User?> login(String email, String password) async {
    try {
      auth.UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        await _updateUserLastSeen(userCredential.user!.uid);
        return User(
          id: userCredential.user!.uid,
          email: userCredential.user!.email ?? '',
          name: userCredential.user!.displayName ?? '',
          phone: userCredential.user!.phoneNumber ?? '',
          role: 'customer',
          createdAt: DateTime.now(),
        );
      }
      return null;
    } on auth.FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Register new user
  Future<User?> register(
    String email,
    String password,
    String name,
    String phone,
    String role,
  ) async {
    try {
      auth.UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        // Create user document in Firestore
        User user = User(
          id: userCredential.user!.uid,
          email: email,
          name: name,
          phone: phone,
          role: role,
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(userCredential.user!.uid)
            .set(user.toMap());

        return user;
      }
      return null;
    } on auth.FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Get user data from Firestore
  Future<User?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();

      if (doc.exists) {
        return User.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }

  // Update user profile
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .update(data);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Update last seen
  Future<void> _updateUserLastSeen(String uid) async {
    try {
      await _firestore.collection(AppConstants.usersCollection).doc(uid).update(
        {'lastSeen': DateTime.now().toIso8601String()},
      );
    } catch (e) {
      // Silent fail for last seen update
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on auth.FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Handle auth errors
  String _handleAuthError(auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Wrong password';
      case 'email-already-in-use':
        return 'Email already in use';
      case 'invalid-email':
        return 'Invalid email address';
      case 'weak-password':
        return 'Password is too weak';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many requests. Please try again later';
      case 'network-request-failed':
        return 'Network error. Please check your connection';
      default:
        return 'An error occurred. Please try again';
    }
  }
}
