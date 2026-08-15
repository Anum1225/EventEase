# EventEase — Multi-Tier Event Management Platform

## 1. Project Overview
EventEase is an institutional, multi-tier campus and community event management application engineered with Flutter and Firebase. It unifies three distinct user roles—**Attendees**, **Organizers**, and **Administrators**—into a single cross-platform ecosystem designed to solve event discovery fragmentation, seat capacity race conditions, and ticket fraud. The platform features atomic seat allocation transactions, single-scan ticket validation with instant duplicate rejection, custom ticket-stub pass geometry with radial glows, and comprehensive administrative governance.

---

## 2. Tech Stack

### Core Framework & Architecture
- **Flutter SDK**: `>=3.3.0 <4.0.0` (Dart `>=3.0.0 <4.0.0`)
- **State Management**: `provider: ^6.1.2` (10 dedicated `ChangeNotifier` state providers)
- **Routing**: `go_router: ^14.8.1` (Nested multi-shell navigation with role-based route guards)

### Firebase Services & Packages
- **Firebase Core**: `firebase_core: ^3.12.1` (Multi-platform Firebase initialization)
- **Authentication**: `firebase_auth: ^5.5.1` (Email & password authentication, password resets, role-based claims)
- **Database**: `cloud_firestore: ^5.6.5` (Real-time collections, streams, 7-step atomic capacity transactions)
- **Storage**: `firebase_storage: ^12.4.4` (Media buckets for event banners, profile photos, and memory galleries)
- **Cloud Messaging**: `firebase_messaging: ^15.2.4` (In-app triggers and broadcast notifications)

### UI & Utilities
- **Typography & Theming**: `google_fonts: ^6.2.1` (Manrope + Fraunces with variable weight/wonk axes)
- **QR Pass Rendering**: `qr_flutter: ^4.1.0` (Anti-duplicate security tokens with pure white background preservation)
- **Camera QR Scanner**: `mobile_scanner: ^6.0.7` (Live camera viewfinder, torch control, real-time barcode capture)
- **Image Handling**: `cached_network_image: ^3.4.1`, `image_picker: ^1.1.2`
- **Formatting & Identifiers**: `intl: ^0.20.2`, `uuid: ^4.5.1`, `shared_preferences: ^2.5.3`

---

## 3. Prerequisites
Before setting up the project, ensure you have the following installed on your machine:
- **Flutter SDK**: Version 3.3.0 or higher (`flutter --version`)
- **Dart SDK**: Version 3.0.0 or higher
- **Android Studio** (with Android SDK Platform & Build-Tools) or **VS Code** with Flutter extension
- **Node.js & npm** (for Firebase CLI)
- **Firebase CLI**: Installed globally (`npm install -g firebase-tools`)
- **A Google / Firebase Account** to create and connect a project

---

## 4. Setup Instructions

Follow these steps to configure and launch EventEase locally:

### Step 1: Clone or Extract the Project
```bash
git clone https://github.com/your-org/EventEase.git
cd EventEase
```

### Step 2: Install Flutter Dependencies
```bash
flutter pub get
```

### Step 3: Firebase Project Configuration
1. Open the [Firebase Console](https://console.firebase.google.com/) and click **Add Project**. Name it `EventEase` (or your preferred name).
2. Enable the following services in the console:
   - **Authentication**: Enable the **Email/Password** sign-in method.
   - **Cloud Firestore**: Create database in **Production mode** (rules will be deployed in Step 5).
   - **Cloud Storage**: Enable storage in default bucket.
   - **Cloud Messaging (FCM)**: Enable for notification dispatches.

### Step 4: Configure FlutterFire
Log in to Firebase via CLI and generate platform configuration:
```bash
firebase login
dart pub global activate flutterfire_cli
flutterfire configure
```
Select your Firebase project and platforms (Android, iOS, Web). This generates `lib/firebase_options.dart`.

### Step 5: Deploy Security Rules
Deploy the database and storage security rules included in the repository:
```bash
firebase deploy --only firestore:rules,storage
```

---

## 5. Running the App

### Running in Debug Mode
Launch the app on a connected physical device, Android emulator, or Chrome:
```bash
# Run on default connected device / emulator
flutter run

# Run on Chrome web browser
flutter run -d chrome
```

### Building the Release APK
To compile the production release APK for Android deployment:
```bash
flutter build apk --release
```
The compiled APK will be located at:
```
build/app/outputs/flutter-apk/app-release.apk
```

---

## 6. Project Structure

EventEase strictly enforces a 4-layered architecture to decouple business logic from UI rendering:

```
lib/
├── app.dart                       # Root EventEaseApp widget & GoRouter with role guards
├── main.dart                      # App entrypoint & Firebase initialization
├── firebase_options.dart          # Firebase project configuration bindings
│
├── core/                          # Cross-cutting foundational infrastructure
│   ├── constants/                 # Roles, event statuses, categories, collection names
│   ├── theme/                     # AppColors (Signal Lime/Indigo), AppTypography, AppTheme
│   ├── utils/                     # DateFormatter, Validators, ContrastChecker
│   └── widgets/                   # AppButton, AppCard, CategoryChip, StatusBadge, QRPassCard
│
├── models/                        # Immutable data models & JSON/Firestore mappers
│   ├── user_model.dart            # User profile, role flags, notification preferences
│   ├── event_model.dart           # Event details, capacity math, remaining seats
│   ├── registration_model.dart    # Ticket pass token, confirmed/cancelled status
│   ├── attendance_model.dart      # Verified single check-in record with timestamp
│   ├── notification_model.dart    # Push alerts and trigger broadcasts
│   ├── feedback_model.dart        # 1-5 star ratings and reviews
│   ├── gallery_model.dart         # Event memory photo metadata
│   ├── favorite_model.dart        # Bookmarked event references
│   └── contact_message_model.dart # Inquiries sent to administrators
│
├── repositories/                  # Data access layer & atomic Firestore transactions
│   ├── user_repository.dart
│   ├── event_repository.dart
│   ├── registration_repository.dart  # 7-step atomic transaction seat reservation
│   ├── attendance_repository.dart    # QR scanner check-in & duplicate enforcement
│   ├── notification_repository.dart
│   ├── feedback_repository.dart      # 1 review per attendee per event rule
│   ├── gallery_repository.dart
│   ├── favorite_repository.dart
│   └── contact_repository.dart
│
├── services/                      # Low-level service connectors
│   ├── auth_service.dart          # Firebase Auth abstraction
│   ├── qr_service.dart            # Anti-tamper QR token generator
│   ├── storage_service.dart       # Cloud Storage image uploader
│   ├── notification_service.dart  # FCM push dispatcher
│   └── seed_data_service.dart     # SRS 1.9 Test dataset seeder
│
├── providers/                     # State management layer (ChangeNotifier)
│   ├── auth_provider.dart
│   ├── theme_provider.dart
│   ├── event_provider.dart
│   ├── registration_provider.dart
│   ├── attendance_provider.dart
│   ├── admin_provider.dart
│   ├── notification_provider.dart
│   ├── feedback_provider.dart
│   ├── gallery_provider.dart
│   └── contact_provider.dart
│
└── features/                      # Presentation layer (UI screens & components)
    ├── auth/screens/              # Login, Register, Forgot Password, Pending Host screen
    ├── attendee/screens/          # Home Discover, Event Details, My Events, Pass, Reviews
    ├── organizer/screens/         # Dashboard, Create Event, Scanner, Roster, Announcements
    ├── admin/screens/             # Command Center, Approvals, Users, Events, Moderation
    └── shared/screens/            # About Us, Contact Us, Fullscreen Memory Gallery
```

---

## 7. Demo Credentials

The application includes an automated test dataset seeder matching the SRS 1.9 Demonstration Checklist. Evaluators can also use the **Quick Demo Fill** buttons on the Login screen:

| Role | Email | Password | Account Details & Permissions |
|---|---|---|---|
| **System Admin** | `admin@eventease.com` | `AdminPass123!` | Full administrative privileges, approval queue, user bans, analytics |
| **Verified Host** | `tech.club@eventease.com` | `OrgPass123!` | Approved organizer, hosts tech events, attendance QR scanning |
| **Verified Host** | `arts.society@eventease.com` | `OrgPass123!` | Approved organizer, hosts arts/culture showcases |
| **Pending Host** | `pending.host@eventease.com` | `OrgPass123!` | Applicant pending admin verification (restricted access) |
| **Attendee 1** | `attendee1@eventease.com` | `AttendeePass123!` | Standard attendee with pre-registered active ticket passes |
| **Attendee 2** | `attendee2@eventease.com` | `AttendeePass123!` | Standard attendee for testing capacity and duplicate check-in |

> **Note**: To populate or refresh this dataset in Firestore at any time, log in as `admin@eventease.com`, navigate to the **Command Center Overview**, and tap **"Seed Demo Data Now"**.

---

## 8. Assumptions & Known Limitations

### SRS Institutional Assumptions
1. **One Account Per Email**: Each user account is uniquely bound to one primary email address across all roles.
2. **Single Primary Organizer**: Every created event is associated with a single primary organizer accountable for event execution and attendance scanning.
3. **Capacity Control**: Seat availability is strictly governed by `maxParticipants` and enforced via atomic Firestore database transactions.
4. **Public Discovery**: Only events in `approved` status are publicly discoverable on the Home screen. Pending submissions remain isolated to the host and administrators.
5. **Post-Event Feedback**: Attendee reviews and 1-5 star ratings are unlocked only after the event date has elapsed (`isCompleted == true`), with exactly one review permitted per attendee.
6. **QR Pass Integrity**: Ticket passes encode a cryptographically unique token referencing a verified `RegistrationModel`. Check-in records are single-instance; subsequent scans trigger duplicate rejection warnings.
7. **Trusted Administration**: System administrators have institutional oversight to audit, moderate, or remove any event, user account, or uploaded media asset.

### Implementation Specifics
- **Camera Scanner**: The QR code scanner utilizes `mobile_scanner` with live camera access. When evaluating on a desktop browser or simulator without physical camera hardware, test passes can be verified by entering payloads or running on physical devices.
- **Push Alerts**: In-app notifications are delivered and persisted in real time via Firestore streams. Background push delivery requires platform APNs/FCM device tokens.

---

## 9. Testing

### Running Automated Test Suite
Execute the complete automated unit and widget test suite:
```bash
flutter test
```

### Static Analysis
Verify that all source files conform to strict Dart and Flutter lint rules:
```bash
flutter analyze
```

### Manual Testing Verification Checklist

| Test Domain | Target Scenario | Verification Steps & Expected Outcome |
|---|---|---|
| **Authentication** | Registration & Role Routing | Register as new user; check that applicant host enters pending approval while attendees land on Discover. |
| **Event Creation** | Validation & Capacity | Fill event creation form; verify inline validation on required fields and positive capacity integer. |
| **Approval Workflow** | Admin Moderation | Log in as admin; approve or reject pending event with mandatory justification; verify status update in host dashboard. |
| **Atomic Registration** | Seat Capacity Reservation | Register for an event; verify seat count increments by 1 and ticket pass is instantly generated. |
| **QR Attendance** | Single Check-In & Duplicate Guard | Scan ticket pass via Organizer Scanner; verify success check-in on first scan, and **duplicate alert** on subsequent scans. |
| **Reviews & Feedback** | Post-Completion Limit | Leave 5-star rating on a completed event; verify review renders on event details and duplicate submission is locked. |
| **User Administration** | Deactivation & Re-activation | Deactivate user from Admin User Directory; verify immediate login lockout and clean reactivation. |
