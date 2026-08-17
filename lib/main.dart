import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app.dart';
import 'firebase_options.dart';
import 'services/local_data_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Allow runtime font fetching with safe fallbacks
  try {
    GoogleFonts.config.allowRuntimeFetching = true;
  } catch (_) {}

  // Initialize Local persistent database cache
  try {
    await LocalDataStore().init();
  } catch (e) {
    debugPrint('LocalDataStore init note: $e');
  }

  // Initialize Firebase if live project credentials are provided
  if (DefaultFirebaseOptions.isLiveFirebaseConfigured) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await LocalDataStore().syncFromFirestore();
    } catch (e) {
      debugPrint('Firebase initialization note: $e');
    }
  }

  runApp(const EventEaseApp());
}
