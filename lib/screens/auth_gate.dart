import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:life/providers/user_provider.dart';
import 'package:life/screens/login.dart';
import 'package:life/screens/home.dart';

class AuthGateScreen extends StatelessWidget {
  const AuthGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          if (snapshot.hasData) {
            // Update the userId of the UserProvider after the widget
            // has been built. Otherwise, we get an error
            Future.microtask(() {
              // Get the user provider and update its state
              UserProvider userProvider =
                  Provider.of<UserProvider>(context, listen: false);

              userProvider.userId = snapshot.data!.uid;
            });

            return const HomeScreen();
          } else {
            // No user data, show login screen
            return const LoginScreen();
          }
        } else {
          // Waiting for connection state, show loading indicator
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
      },
    );
  }
}
