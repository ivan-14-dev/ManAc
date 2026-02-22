# Manac - Stock Management App

A comprehensive stock management mobile application for Android and iOS built with Flutter. Features real-time Firebase synchronization with offline support.

## App Screenshots

| | | |
|:-------------------------:|:-------------------------:|:-------------------------:|
| <img src="manac/catpture/2b595ec5-929c-4353-9a95-f1875775443b.jpeg" width="200" /> | <img src="manac/catpture/95d4d3f9-637a-4cf0-8ec0-b8e5c38dbb34.jpeg" width="200" /> | <img src="manac/catpture/afba498b-ab24-4526-bb3a-cfaa13151687.jpeg" width="200" /> |
| <img src="manac/catpture/c25549cf-a6d9-41f6-acc5-833b0bef6968.jpeg" width="200" /> | | |

## Features

- 📦 **Stock Management**
  - Add, edit, and delete stock items
  - Track quantities, prices, and locations
  - Low stock alerts
  - Barcode support
  - Category filtering and search

- 🔄 **Real-time Synchronization**
  - Firebase Cloud Firestore integration
  - Offline-first architecture with local storage
  - Automatic sync when online
  - Background sync for pending changes
  - Connection hours tracking

- 📊 **Activities & History**
  - Track all stock movements
  - User activity logging
  - Sync history
  - Connection sessions

- 👤 **User Management**
  - Firebase Authentication
  - User profiles
  - Session tracking

- 📱 **Cross-Platform**
  - Native Android app
  - Native iOS app
  - Responsive design
  - Material Design 3

## Tech Stack

- **Framework**: Flutter 3.x
- **Language**: Dart
- **Backend**: Firebase (Firestore, Authentication)
- **Local Storage**: Hive
- **State Management**: Provider
- **Background Tasks**: Workmanager
- **Connectivity**: Connectivity Plus

## Project Structure

```
manac/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── callback_dispatcher.dart   # Workmanager callback
│   ├── firebase_options.dart     # Firebase configuration
│   ├── models/
│   │   ├── stock_item.dart       # Stock item model
│   │   ├── stock_movement.dart   # Stock movement model
│   │   ├── sync_queue_item.dart # Sync queue model
│   │   └── activity.dart         # Activity log model
│   ├── providers/
│   │   ├── stock_provider.dart   # Stock state management
│   │   ├── sync_provider.dart    # Sync state management
│   │   └── auth_provider.dart    # Auth state management
│   ├── services/
│   │   ├── local_storage_service.dart  # Hive local storage
│   │   ├── firebase_service.dart       # Firebase operations
│   │   ├── sync_service.dart           # Sync logic
│   │   └── connectivity_service.dart   # Network status
│   └── screens/
│       ├── main_screen.dart            # Main navigation
│       ├── stock_list_screen.dart      # Stock list & details
│       ├── activities_screen.dart      # Activity history
│       ├── sync_status_screen.dart     # Sync status & stats
│       └── settings_screen.dart        # App settings
├── android/
│   └── app/src/main/
│       ├── AndroidManifest.xml
│       └── kotlin/com/example/manac/
│           └── Application.kt
└── ios/
    └── Runner/
```

## Setup Instructions

### 1. Install Flutter

Follow the [Flutter installation guide](https://flutter.dev/docs/get-started/install) for your platform.

### 2. Clone and Setup

```bash
cd /home/eye-of-god/Documents/script/common/Mobile/ManAc
cd manac
flutter pub get
```

### 3. Firebase Setup

1. Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)

2. Enable Authentication:
   - Go to Authentication > Sign-in method
   - Enable Email/Password

3. Create Firestore Database:
   - Go to Firestore Database
   - Create database in test mode (or production with rules)

4. Add Firebase to your apps:
   - Android: Add google-services.json to android/app/
   - iOS: Add GoogleService-Info.plist to ios/Runner/

5. Update firebase_options.dart with your Firebase config

### 4. Configure Firebase Security Rules

For development, use these Firestore rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

### 5. Run the App

```bash
flutter run
```

## Building for Release

### Android

```bash
flutter build apk --release
```

### iOS

```bash
flutter build ipa --release
```

## Key Features Explained

### Offline Support

The app uses Hive for local storage. All stock data is stored locally and synced to Firebase when online. Changes made offline are queued and synced automatically when connection is restored.

### Sync Queue

Pending changes are stored in a sync queue with:
- Action type (create, update, delete)
- Collection name
- Data payload
- Retry count (max 3 attempts)
- Timestamps

### Connection Tracking

The app tracks:
- Online/offline status
- Connection duration
- Session history
- Last sync time

### Background Sync

Workmanager handles periodic background sync every 15 minutes when connected to network.

## Dependencies

All dependencies are managed in `pubspec.yaml`:

- firebase_core, firebase_auth, cloud_firestore
- hive, hive_flutter
- provider, get
- connectivity_plus
- workmanager
- intl, uuid

## Configuration

### Sync Interval

Modify sync frequency in settings or code:
```dart
Workmanager().registerPeriodicTask(
  'periodic-sync',
  'syncTask',
  frequency: const Duration(minutes: 15),
);
```

### Default Categories

Edit in code or add custom categories:
```dart
// In stock_provider.dart
final List<String> defaultCategories = [
  'Electronics',
  'Clothing',
  'Food',
  'Beverages',
  'Office Supplies',
];
```

## License

This project is open source and available under the Apache License.
