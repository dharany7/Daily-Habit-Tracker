import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/habit_provider.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, HabitProvider>(
      builder: (context, authProvider, habitProvider, child) {
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (authProvider.isAuthenticated) {
          return const DashboardScreen();
        }

        // Clear user data when user is not authenticated
        WidgetsBinding.instance.addPostFrameCallback((_) {
          habitProvider.clearUserData();
        });

        return const LoginScreen();
      },
    );
  }
}
