import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Allow runtime font fetching with safe fallbacks
  try {
    GoogleFonts.config.allowRuntimeFetching = true;
  } catch (_) {}

  // Initialize Firebase if live project credentials are provided
  if (DefaultFirebaseOptions.isLiveFirebaseConfigured) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      debugPrint('Firebase initialization note: $e');
    }
  }

  runApp(const EventEaseApp());
}
