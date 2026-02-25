import 'package:app_envio/services/auth_service.dart';
import 'package:app_envio/view/home_page.dart';
import 'package:app_envio/view/login_page.dart';
import 'package:flutter/material.dart';

class AuthWrapper extends StatelessWidget {
  final _authService = AuthService();

  AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          );
        }

        if (snapshot.hasData) {
          return const HomePage();
        } else {
          return const LoginPage();
        }
      },
    );
  }
}
