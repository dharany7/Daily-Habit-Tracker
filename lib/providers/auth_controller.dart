import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/auth_state.dart';

final authControllerProvider = AsyncNotifierProvider<AuthController, AuthState>(() {
  return AuthController();
});

class AuthController extends AsyncNotifier<AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  AuthState build() {
    return const AuthState.initial();
  }

  // Sign in with email and password
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final User? user = result.user;
      if (user != null) {
        // Fetch user data from Firestore
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        
        state = AsyncValue.data(AuthState.authenticated(
          user: user,
          userData: userDoc.data(),
        ));
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred';
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found for this email.';
          break;
        case 'wrong-password':
          errorMessage = 'Wrong password provided.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address.';
          break;
        case 'user-disabled':
          errorMessage = 'This user account has been disabled.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many requests. Try again later.';
          break;
      }
      state = AsyncValue.error(errorMessage, StackTrace.current);
    } catch (e) {
      state = AsyncValue.error('An unexpected error occurred: ${e.toString()}', StackTrace.current);
    }
  }

  // Sign up with email and password
  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final User? user = result.user;
      if (user != null) {
        // Create user document in Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
          'habits': [], // Initialize empty habits array
          'stats': {
            'totalHabits': 0,
            'completedToday': 0,
            'streak': 0,
          },
        });

        state = AsyncValue.data(AuthState.authenticated(
          user: user,
          userData: {
            'uid': user.uid,
            'email': email,
            'habits': [],
            'stats': {
              'totalHabits': 0,
              'completedToday': 0,
              'streak': 0,
            },
          },
        ));
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred';
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'The password provided is too weak.';
          break;
        case 'email-already-in-use':
          errorMessage = 'An account already exists for this email.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Email/password accounts are not enabled.';
          break;
      }
      state = AsyncValue.error(errorMessage, StackTrace.current);
    } catch (e) {
      state = AsyncValue.error('An unexpected error occurred: ${e.toString()}', StackTrace.current);
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      state = const AsyncValue.data(AuthState.initial());
    } catch (e) {
      state = AsyncValue.error('Error signing out: ${e.toString()}', StackTrace.current);
    }
  }

  // Check current user authentication state
  Future<void> checkAuthState() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
        state = AsyncValue.data(AuthState.authenticated(
          user: currentUser,
          userData: userDoc.data(),
        ));
      } catch (e) {
        state = const AsyncValue.data(AuthState.initial());
      }
    } else {
      state = const AsyncValue.data(AuthState.initial());
    }
  }

  // Clear error state
  void clearError() {
    if (state.hasError) {
      state = const AsyncValue.data(AuthState.initial());
    }
  }

  // Update user data in Firestore
  Future<void> updateUserData(Map<String, dynamic> data) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        await _firestore.collection('users').doc(currentUser.uid).update(data);
        
        // Refresh user data
        final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
        state = AsyncValue.data(AuthState.authenticated(
          user: currentUser,
          userData: userDoc.data(),
        ));
      } catch (e) {
        state = AsyncValue.error('Error updating user data: ${e.toString()}', StackTrace.current);
      }
    }
  }
}
