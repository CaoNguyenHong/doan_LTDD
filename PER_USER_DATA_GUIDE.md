# SpendSage - Per-User Data Implementation

## 📋 Overview

SpendSage đã được cập nhật để hỗ trợ **per-user data isolation** - mỗi user có dữ liệu riêng biệt trong Firebase Firestore.

## 🏗️ Architecture

### Data Structure
```
users/
├── {uid}/
│   ├── transactions/
│   ├── accounts/
│   ├── budgets/
│   ├── recurring/
│   ├── expenses/
│   ├── learned/
│   └── settings/
│       └── main
```

### Key Components

1. **FirestoreDataSource** - Centralized data access with UID-based paths
2. **AuthGate** - Authentication routing with provider initialization
3. **AuthRepo** - User registration with profile creation
4. **Providers** - UID-aware data management

## 🔧 Setup Instructions

### 1. Firebase Rules
Deploy the updated Firestore rules:
```bash
firebase deploy --only firestore:rules
```

Rules ensure:
- Users can only access their own data (`users/{uid}/...`)
- All other collections are blocked

### 2. Authentication
- Enable **Email/Password** provider in Firebase Console
- Users are automatically created with profile documents

### 3. Data Flow
1. **Sign Up** → Creates `users/{uid}` document
2. **Login** → AuthGate initializes providers with UID
3. **Data Operations** → All CRUD operations use UID-based paths

## 🧪 Testing

### Manual Testing
1. **Create User A** → Add some transactions
2. **Logout** → **Create User B** → Should see empty data
3. **Login User A** → Should see original data

### Debug Tools
Use `PerUserSelfTest` widget to:
- Create test transactions
- Verify Firebase structure
- Check data isolation

## 📁 File Structure

```
lib/
├── auth/
│   ├── auth_gate.dart          # Authentication routing
│   └── auth_repo.dart          # User registration & login
├── data/
│   └── firestore_data_source.dart  # UID-based data access
├── providers/
│   ├── transaction_provider.dart    # Transaction management
│   ├── account_provider.dart        # Account management
│   ├── budget_provider.dart         # Budget management
│   ├── recurring_provider.dart      # Recurring transactions
│   ├── expense_provider.dart        # Expense management
│   └── settings_provider.dart       # User settings
├── debug/
│   └── per_user_self_test.dart      # Testing utilities
└── main.dart                         # App entry point
```

## 🔒 Security

### Firestore Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // All user data under /users/{uid}/...
    match /users/{uid}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
    
    // Block everything else
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

### Data Validation
- All providers validate UID before operations
- Firestore rules enforce per-user access
- No cross-user data leakage possible

## 🚀 Deployment

### Firebase Rules
```bash
# Deploy rules
firebase deploy --only firestore:rules

# Verify deployment
firebase firestore:rules:get
```

### App Build
```bash
# Android
flutter build apk --release

# Web
flutter build web --release
```

## 🐛 Troubleshooting

### Common Issues

1. **"Permission denied" errors**
   - Check Firestore rules deployment
   - Verify user authentication status

2. **Data not loading**
   - Check UID in provider initialization
   - Verify Firebase project configuration

3. **Cross-user data leakage**
   - Check Firestore rules
   - Verify provider UID usage

### Debug Steps

1. **Check Authentication**
   ```dart
   print('Current UID: ${FirebaseAuth.instance.currentUser?.uid}');
   ```

2. **Verify Firebase Path**
   ```dart
   print('Collection path: users/${uid}/transactions');
   ```

3. **Test Data Isolation**
   - Use `PerUserSelfTest` widget
   - Create test data for multiple users
   - Verify data separation

## 📝 TODO Items

- [ ] Add more currency support
- [ ] Implement data export/import
- [ ] Add user profile management
- [ ] Implement data backup
- [ ] Add admin panel for user management

## 🔗 Related Files

- `firestore.rules` - Security rules
- `lib/auth/auth_gate.dart` - Authentication flow
- `lib/data/firestore_data_source.dart` - Data access layer
- `lib/providers/*_provider.dart` - State management
- `lib/debug/per_user_self_test.dart` - Testing utilities

---

**Note**: This implementation ensures complete data isolation between users while maintaining a clean, scalable architecture.


