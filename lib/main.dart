import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'package:life/providers/user_provider.dart';
import 'package:life/screens/auth_gate.dart';
import 'package:life/firebase_options.dart';

void main() async {
  // Make sure the widgets are bound to the engine before running any logic
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => UserProvider(),
      child: MaterialApp(
        title: 'Life App',
        darkTheme:
            ThemeData(brightness: Brightness.dark, primarySwatch: Colors.brown),
        themeMode: ThemeMode.dark,
        home: const AuthGateScreen(),
      ),
    );
  }
}
