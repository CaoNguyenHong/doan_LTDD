# Firebase Setup Guide for SpendSage

## 🔥 Firebase Configuration

### 1. Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project"
3. Enter project name: `spend-sage-app` (or your preferred name)
4. Enable Google Analytics (optional)
5. Choose your region

### 2. Enable Authentication
1. In Firebase Console, go to **Authentication** → **Sign-in method**
2. Enable **Email/Password**
3. Enable **Google** (optional)
4. For Google Sign-in, add your app's SHA-1 fingerprint:
   ```bash
   # Get SHA-1 for Android
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```

### 3. Enable Firestore Database
1. Go to **Firestore Database** → **Create database**
2. Choose **Start in test mode** (we'll add security rules later)
3. Select your region

### 4. Update Firebase Configuration
Replace the placeholder values in `lib/firebase_options.dart`:

```dart
// TODO(CURSOR): Update these values with your actual Firebase config
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'YOUR_WEB_API_KEY',
  appId: 'YOUR_WEB_APP_ID',
  messagingSenderId: 'YOUR_SENDER_ID',
  projectId: 'your-project-id',
  authDomain: 'your-project-id.firebaseapp.com',
  storageBucket: 'your-project-id.appspot.com',
  measurementId: 'YOUR_MEASUREMENT_ID',
);
```

### 5. Deploy Security Rules
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase in your project
firebase init firestore

# Deploy rules
firebase deploy --only firestore:rules
```

## 🚀 Running the App

### Prerequisites
- Flutter 3.24+
- Dart 3.x
- Firebase project configured

### Steps
1. **Install dependencies:**
   ```bash
   flutter pub get
   ```

2. **Update Firebase config:**
   - Replace values in `lib/firebase_options.dart`
   - Or run `flutterfire configure` if you have the CLI

3. **Run the app:**
   ```bash
   # For web
   flutter run -d chrome
   
   # For Android
   flutter run
   
   # For Windows
   flutter run -d windows
   ```

## 🔒 Security Rules

The app includes comprehensive Firestore security rules in `firestore.rules`:

- **User isolation**: Users can only access their own data
- **Data validation**: Ensures expense data integrity
- **Authentication required**: All operations require valid authentication

## 📱 Features

### Authentication
- ✅ Email/Password sign up and sign in
- ✅ Google Sign-in (optional)
- ✅ Password reset
- ✅ Sign out

### Data Management
- ✅ Real-time expense tracking
- ✅ Cloud sync across devices
- ✅ Offline support with Firestore cache
- ✅ Settings synchronization

### Migration
- ✅ Optional Hive → Firestore migration
- ✅ One-time data transfer
- ✅ Preserves existing data

## 🛠️ Development

### Firebase Emulators (Optional)
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Start emulators
firebase emulators:start --only firestore,auth

# In your app, connect to emulators (uncomment in main.dart)
# FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
# FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
```

### Testing
```bash
# Run tests
flutter test

# Run integration tests
flutter drive --target=test_driver/app.dart
```

## 📊 Database Schema

### Firestore Structure
```
users/{uid}/
├── settings/
│   └── user_settings (doc)
│       ├── currency: string
│       ├── darkMode: boolean
│       ├── dailyLimit: number
│       ├── weeklyLimit: number
│       ├── monthlyLimit: number
│       ├── yearlyLimit: number
│       └── updatedAt: timestamp
├── expenses/{expenseId} (sub-collection)
│   ├── category: string
│   ├── amount: number
│   ├── description: string
│   ├── dateTime: timestamp
│   ├── createdAt: timestamp
│   ├── updatedAt: timestamp
│   └── deleted: boolean
└── learned/{word} (sub-collection)
    ├── category: string
    ├── frequency: number
    └── updatedAt: timestamp
```

## 🔧 Troubleshooting

### Common Issues

1. **"Firebase not initialized"**
   - Ensure `firebase_options.dart` has correct values
   - Check if Firebase project is active

2. **"Permission denied"**
   - Verify Firestore security rules are deployed
   - Check if user is authenticated

3. **"Google Sign-in not working"**
   - Add SHA-1 fingerprint to Firebase Console
   - Ensure Google Sign-in is enabled

4. **"Build failed"**
   - Run `flutter clean && flutter pub get`
   - Check Firebase dependencies in `pubspec.yaml`

### Debug Mode
```bash
# Enable debug logging
flutter run --debug

# Check Firebase logs
firebase functions:log
```

## 📝 TODO Items

- [ ] Replace placeholder values in `firebase_options.dart`
- [ ] Add SHA-1 fingerprint for Google Sign-in
- [ ] Deploy Firestore security rules
- [ ] Test on all platforms (Android, Web, Windows)
- [ ] Set up Firebase Analytics (optional)
- [ ] Configure Firebase Crashlytics (optional)

## 🎯 Next Steps

1. **Production Setup:**
   - Create production Firebase project
   - Configure proper security rules
   - Set up monitoring and alerts

2. **Advanced Features:**
   - Push notifications
   - Data export/import
   - Multi-user support
   - Advanced analytics

3. **Performance:**
   - Optimize Firestore queries
   - Implement pagination
   - Add caching strategies
