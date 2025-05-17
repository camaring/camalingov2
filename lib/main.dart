import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'constants.dart';
import 'screens/splash/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  print('✅ Firebase initialized: ${Firebase.app().name}');
  print('   Project ID: ${Firebase.app().options.projectId}');
  print('   App ID:     ${Firebase.app().options.appId}');
  print('   API key:    ${Firebase.app().options.apiKey}');
  print('   Auth domain: ${Firebase.app().options.authDomain}');
  print('   Storage URL: ${Firebase.app().options.storageBucket}');
  print('   Messaging URL: ${Firebase.app().options.messagingSenderId}');
  // 2. Prueba de conexión a Firestore
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('connection_test')
        .doc('ping')
        .get();
    if (snapshot.exists) {
      print('✅ Firestore reachable, document data: ${snapshot.data()}');
    } else {
      print('ℹ️ Firestore reachable, pero el doc “connection_test/ping” no existe.');
    }
  } catch (e) {
    print('❌ Error conectando a Firestore: $e');
  }
  final user = FirebaseAuth.instance.currentUser;
print(user == null
  ? 'No hay usuario logueado (pero Firebase está funcionando)'
  : 'Usuario logueado: ${user.uid}');
try {
  final cred = await FirebaseAuth.instance.signInAnonymously();
  print('✅ Anon user signed in: ${cred.user!.uid}');
} catch (e) {
  print('❌ Error en Auth anon: $e');
}
try {
  final cred = await FirebaseAuth.instance
    .signInWithEmailAndPassword(
      email: 'camiman13@hotmail.com', 
      password: 'camilo12'
    );
  print('✅ Signed in user: ${cred.user!.email}');
} catch (e) {
  print('❌ Error en Auth email/pass: $e');
}


  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
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
      home: const SplashScreen(),
    );
  }
}


// ...