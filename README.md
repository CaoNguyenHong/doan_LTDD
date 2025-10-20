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
# Web
flutter run -d chrome

# Android (with emulator)
flutter run -d emulator-5554

# Android (with physical device)
flutter run -d <device-id>
```

## Firebase (Optional)

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase
flutterfire configure
# This generates: lib/firebase_options.dart
```

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
