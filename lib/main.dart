import 'package:camalingo/screens/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'constants.dart';

import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';

import 'package:intl/date_symbol_data_local.dart';

/// Application entry point.
/// 
/// Initializes Firebase services and tests Firestore and Auth connections
/// before launching the Flutter application.
Future<void> main() async {
  // Ensure Flutter bindings are initialized before any plugins.
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 1. Firebase initialization details (for debugging purposes).
  // Log the Firebase app configuration values.
  print('✅ Firebase initialized: ${Firebase.app().name}');
  // Print project, app, and API key information
  print('   Project ID: ${Firebase.app().options.projectId}');
  print('   App ID:     ${Firebase.app().options.appId}');
  print('   API key:    ${Firebase.app().options.apiKey}');
  // Print authentication domain and storage bucket
  print('   Auth domain: ${Firebase.app().options.authDomain}');
  print('   Storage URL: ${Firebase.app().options.storageBucket}');
  print('   Messaging URL: ${Firebase.app().options.messagingSenderId}');
  print('   Database URL: ${Firebase.app().options.databaseURL}');
  print('   Storage bucket: ${Firebase.app().options.storageBucket}');
 
  // 2. Test Firestore connectivity by reading a known document.
  try {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('connection_test')
            .doc('ping')
            .get();
    if (snapshot.exists) {
      // Document exists: Firestore is reachable and returned data.
      print('✅ Firestore reachable, document data: ${snapshot.data()}');
    } else {
      // Document missing: Firestore is reachable but document doesn't exist.
      print(
        'ℹ️ Firestore reachable, pero el doc “connection_test/ping” no existe.',
      );
    }
  } catch (e) {
    // Handle Firestore connection errors.
    print('❌ Error conectando a Firestore: $e');
  }
  final user = FirebaseAuth.instance.currentUser;
  print(
    user == null
        ? 'No hay usuario logueado (pero Firebase está funcionando)'
        : 'Usuario logueado: ${user.uid}',
  );
  // 3. Test anonymous authentication.
  try {
    final cred = await FirebaseAuth.instance.signInAnonymously();
    print('✅ Anon user signed in: ${cred.user!.uid}');
  } catch (e) {
    print('❌ Error en Auth anon: $e');
  }
  // 4. Test email/password authentication.
  try {
    final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: 'camiman13@hotmail.com',
      password: 'camilo12',
    );
    print('✅ Signed in user: ${cred.user!.email}');
  } catch (e) {
    print('❌ Error en Auth email/pass: $e');
  }

  // Initialize locale-specific date formatting for Colombian Spanish.
  await initializeDateFormatting('es_CO', null);

  // Launch the Flutter application.
  runApp(const MyApp());
}

/// Root widget of the application.
/// 
/// Sets up theme, routes, and the initial screen.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Configure the MaterialApp with theme and routing.
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Savemeleon',
      theme: ThemeData(
        primaryColor: AppColors.primaryGreen,
        scaffoldBackgroundColor: AppColors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.black),
        ),
      ),
      home: const LoginScreen(), // Default route: login screen.
      routes: {
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignupScreen(),
        '/home': (_) => const HomeScreen(), // Home screen.
      },
    );
  }
}


// ...