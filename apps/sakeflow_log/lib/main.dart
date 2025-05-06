import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'auth_gate.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'home_screen.dart';
import 'ai_label_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sakeflow Logs',
      initialRoute: '/login',
      routes: {
        '/login':
            (context) => SignInScreen(
              providers: [GoogleProvider(clientId: 'YOUR_GOOGLE_CLIENT_ID')],
              actions: [
                AuthStateChangeAction<SignedIn>((context, state) {
                  Navigator.pushReplacementNamed(context, '/home');
                }),
              ],
            ),
        '/home': (context) => const HomeScreen(),
        '/ai-label': (context) => const AiLabelScreen(),
      },
    );
  }
}
