import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'screens/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      // Add these options for Android
      options: const FirebaseOptions(
        apiKey: 'AIzaSyDwCN_6OURiGuCgYytonhYiKCX0oHefWik',
        appId: '1:826872773454:android:b8c86f1323b6834cb87c1f',
        messagingSenderId: '826872773454',
        projectId: 'linkedinclone-3ad50',
        storageBucket: 'linkedinclone-3ad50.firebasestorage.app',
      ),
    );
  } catch (e) {
    print('Firebase initialization error: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LinkedIn Clone',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey,
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}
