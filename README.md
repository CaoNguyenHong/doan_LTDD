# SpendSage 💰

A Flutter expense tracking app with AI-powered categorization and Firebase integration.

## Features

- 📊 **Expense Tracking**: Add, edit, and delete expenses with categories
- 🤖 **AI-Powered**: Smart categorization using Google Generative AI (Gemini)
- 📈 **Analytics**: Visual charts and spending insights
- 🔐 **Authentication**: Firebase Auth with Email/Password and Google Sign-in
- ☁️ **Cloud Sync**: Firestore database for cross-device synchronization
- 🎨 **Modern UI**: Material Design 3 with dark/light theme support

## Requirements

- Flutter stable ≥ 3.24, Dart 3.x
- JDK 17, Android SDK 36
- Free disk space ≥ 15 GB

## Setup

```bash
# Check Flutter installation
flutter --version
flutter doctor -v

# Get dependencies
flutter pub get

# (Android) Accept licenses
flutter doctor --android-licenses
```

## Run

```bash
# Clean and get dependencies
flutter clean
flutter pub get

# Deploy Firestore indexes (if using file-based indexes)
firebase deploy --only firestore:indexes

# Run app
flutter run -d emulator-5554

# Hot restart after adding new providers (not hot-reload)
# Press 'R' in terminal or restart the app
```

## Firebase Setup

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase
flutterfire configure
# This generates: lib/firebase_options.dart

# Deploy Firestore indexes (required for queries)
firebase deploy --only firestore:indexes
```

## App Check (Dev)

**Debug Token**: `51b44e19-b636-42a1-8dd0-d86023e040ca`

Thêm token này vào Firebase Console:
1. Vào Firebase Console → App Check
2. Chọn Android app → Manage debug tokens
3. Add token: `51b44e19-b636-42a1-8dd0-d86023e040ca`

**Lưu ý**: Khi release production, bật enforcement và dùng Play Integrity.

## Deploy Firestore Indexes

Sau khi thêm composite indexes vào `firestore.indexes.json`:

```bash
# Deploy indexes to Firebase
firebase deploy --only firestore:indexes
```

**Lưu ý**: Indexes có thể mất vài phút để build. Kiểm tra Firebase Console → Firestore → Indexes để xem trạng thái.

## Environment Variables

> **Important**: Do not commit `.env` files. Use `--dart-define` instead.

```bash
# Run with API key
flutter run -d chrome --dart-define=GEMINI_API_KEY=YOUR_API_KEY

# Run with multiple variables
flutter run -d chrome \
  --dart-define=GEMINI_API_KEY=YOUR_API_KEY \
  --dart-define=FIREBASE_PROJECT_ID=your-project-id
```

## Build

```bash
# Web (Release)
flutter build web --release

# Android (Debug)
flutter build apk --debug

# Android (Release)
flutter build apk --release
```

## Project Structure

```
lib/
├── auth/                 # Authentication (Firebase Auth)
├── data/                 # Data sources (Firestore, Hive)
├── providers/           # State management (Provider)
├── screens/             # UI screens
├── widgets/             # Reusable widgets
├── service/             # Business logic services
└── hive/               # Local data models
```

## Development Notes

- **Firebase**: Currently configured for development with emulator support
- **Authentication**: Ready to enable by uncommenting AuthGate in main.dart
- **Data Migration**: Hive to Firestore migration available
- **CI/CD**: GitHub Actions workflow for automated testing and building

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests: `flutter test`
5. Submit a pull request

## License

This project is licensed under the MIT License.
