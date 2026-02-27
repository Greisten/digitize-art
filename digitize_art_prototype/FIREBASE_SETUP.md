# Firebase Setup Guide

The app now uses Firebase for authentication and user data storage. Follow these steps to configure Firebase:

## Prerequisites

1. A Google account
2. Access to [Firebase Console](https://console.firebase.google.com/)

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter project name: `digitize-art` (or your preferred name)
4. Follow the wizard to complete project creation

## Step 2: Register iOS App

1. In Firebase Console, click the iOS icon
2. Enter iOS bundle ID: `com.digitizeart.app` (or your app's bundle ID)
3. Download `GoogleService-Info.plist`
4. Place it in: `ios/Runner/GoogleService-Info.plist`

## Step 3: Register Android App

1. In Firebase Console, click the Android icon
2. Enter Android package name: `com.digitizeart.digitize_art_prototype` (or your package name)
3. Download `google-services.json`
4. Place it in: `android/app/google-services.json`

## Step 4: Enable Authentication Methods

1. In Firebase Console, go to **Authentication** → **Sign-in method**
2. Enable the following providers:
   - ✅ **Email/Password**
   - ✅ **Google** (add iOS/Android client IDs)
   - ✅ **Apple** (requires Apple Developer account)
   - ✅ **Twitter** (requires Twitter API keys)

### Google Sign-In Configuration

**iOS:**
1. Get iOS Client ID from `GoogleService-Info.plist`
2. Add to `Info.plist`:
```xml
<key>GIDClientID</key>
<string>YOUR_IOS_CLIENT_ID</string>
```

**Android:**
1. Get SHA-1 certificate fingerprint:
```bash
cd android
./gradlew signingReport
```
2. Add SHA-1 to Firebase Console → Project Settings → Android app

### Apple Sign-In Configuration

1. Enable Apple Sign-In in your Apple Developer account
2. Add Sign in with Apple capability in Xcode
3. Configure in Firebase Console

### Twitter/X Sign-In Configuration

1. Create Twitter App at [developer.twitter.com](https://developer.twitter.com)
2. Get API Key and Secret
3. Add to Firebase Console → Authentication → Twitter

## Step 5: Enable Firestore Database

1. Go to **Firestore Database** in Firebase Console
2. Click "Create database"
3. Choose **Production mode** (add security rules later)
4. Select a location close to your users

## Step 6: Configure Firestore Security Rules

Replace the default rules with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own document
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Admin-only access to all users (optional)
    match /users/{userId} {
      allow read: if request.auth != null && 
                     get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
```

## Step 7: Install FlutterFire CLI (Optional but Recommended)

This automates Firebase configuration:

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Run configuration
flutterfire configure
```

This will:
- Create/update Firebase projects
- Generate `firebase_options.dart`
- Configure all platforms automatically

## Step 8: Update Firebase Initialization

If using FlutterFire CLI, update `lib/main.dart`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const DigitizeArtApp());
}
```

## Step 9: Test Authentication

1. Run the app:
```bash
flutter run
```

2. Test each sign-in method:
   - Email/Password registration
   - Google Sign-In
   - Apple Sign-In (iOS only)
   - Twitter Sign-In

## Step 10: Monitor Usage

- **Authentication**: Firebase Console → Authentication → Users
- **Database**: Firebase Console → Firestore Database
- **Analytics** (optional): Firebase Console → Analytics

## Troubleshooting

### Google Sign-In Issues

**iOS:**
- Check `GIDClientID` in `Info.plist`
- Verify bundle ID matches Firebase

**Android:**
- Verify SHA-1 certificate is added to Firebase
- Check package name matches

### Apple Sign-In Issues

- Ensure Apple Sign-In capability is enabled in Xcode
- Check bundle ID has Apple Sign-In enabled in Apple Developer

### Firestore Permission Errors

- Check security rules allow authenticated users
- Verify user is signed in before database operations

## Production Checklist

Before launching:

- [ ] Update Firestore security rules (restrict write access)
- [ ] Enable Firebase Analytics
- [ ] Set up Cloud Functions for sensitive operations
- [ ] Configure proper error logging (Crashlytics)
- [ ] Add email verification requirement (optional)
- [ ] Set up backup strategy for user data
- [ ] Review Firebase pricing (free tier limits)

## Cost Optimization

Firebase free tier includes:
- **Authentication**: Unlimited (free)
- **Firestore**: 50,000 reads/day, 20,000 writes/day
- **Storage**: 1 GB

Monitor usage at: Firebase Console → Usage and billing

## Support

- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev)
- [Firebase Support](https://firebase.google.com/support)

---

**Note:** Keep your `google-services.json` and `GoogleService-Info.plist` files private. Never commit them to public repositories.
