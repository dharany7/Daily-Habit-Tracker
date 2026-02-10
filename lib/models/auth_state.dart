import 'package:firebase_auth/firebase_auth.dart';

class AuthState {
  final bool isLoading;
  final User? user;
  final Map<String, dynamic>? userData;
  final String? error;

  const AuthState({
    this.isLoading = false,
    this.user,
    this.userData,
    this.error,
  });

  const AuthState.initial()
      : isLoading = false,
        user = null,
        userData = null,
        error = null;

  const AuthState.loading()
      : isLoading = true,
        user = null,
        userData = null,
        error = null;

  const AuthState.authenticated({
    required this.user,
    required this.userData,
  }) : isLoading = false,
       error = null;

  const AuthState.error(String error)
      : isLoading = false,
        user = null,
        userData = null,
        error = error;

  bool get isAuthenticated => user != null && !isLoading;
  bool get hasError => error != null;
}
