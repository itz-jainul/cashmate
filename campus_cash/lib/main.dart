import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
    debugPrint(
      'To connect to live Firebase, add your google-services.json file into android/app/',
    );
  }

  runApp(
    const ProviderScope(
      child: CampusCashApp(),
    ),
  );
}
