// ignore_for_file: avoid_print
import 'package:flutter/widgets.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventease/services/seed_data_service.dart';

/// Standalone CLI entrypoint for seeding EventEase demo dataset
/// Usage: dart run tool/seed_data.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('====================================================');
  print(' EventEase - Test Data Seed Pipeline ');
  print('====================================================');

  try {
    print('[1/3] Initializing Firebase connection...');
    await Firebase.initializeApp();

    final firestore = FirebaseFirestore.instance;
    final seedService = SeedDataService(firestore: firestore);

    print('[2/3] Seeding test accounts, events, registrations, attendance, and feedback...');
    await seedService.seedDatabase();

    print('✅ SUCCESS: Seed dataset committed to Firestore.');
    print('   Users created: 9 accounts (1 Admin, 3 Organizers, 5 Attendees)');
    print('   Events created: 10 events across 6 categories');
    print('   Registrations & Attendance: 4 completed check-ins, active tickets');
    print('   Feedback reviews: 3 reviews with ratings and comments');
    print('   Gallery photos: 2 event gallery memories');
    print('\n[3/3] Please consult TEST_CREDENTIALS.md for demo login accounts.');
  } catch (e) {
    print('ℹ️ NOTE: When running via CLI without local google-services credentials,');
    print('  use the built-in Admin Dashboard "Seed Demo Data" button in the app UI,');
    print('  or run within an initialized Flutter runtime.');
    print('  Details: $e');
  }
}
