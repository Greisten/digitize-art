# Authentication System Documentation

## Overview

The Digitize.art app now includes a complete authentication system with support for multiple sign-in methods and user profile management.

## Features

### ✅ Authentication Methods

1. **Email & Password**
   - Traditional sign-up with email verification
   - Password reset functionality
   - Secure password storage via Firebase

2. **Google Sign-In**
   - One-tap Google authentication
   - Automatically imports profile photo and name
   - Works on iOS and Android

3. **Apple Sign-In**
   - Native Apple authentication
   - Privacy-focused (hide email option)
   - iOS only (required for App Store)

4. **Twitter/X Sign-In**
   - OAuth authentication with Twitter
   - Imports username and profile photo

5. **Instagram Sign-In** (Placeholder)
   - Ready for implementation when needed
   - Requires Facebook/Meta configuration

### 📊 User Database

All user data is stored in **Cloud Firestore** with the following structure:

```javascript
users/{userId}
  ├── uid: string
  ├── email: string
  ├── displayName: string (optional)
  ├── photoURL: string (optional)
  ├── phoneNumber: string (optional)
  ├── authProvider: enum (email|google|apple|twitter|instagram)
  ├── createdAt: timestamp
  ├── lastLoginAt: timestamp
  └── metadata: map (custom fields)
```

## User Flow

### First Launch Flow

```
App Launch
    ↓
Language Selection
    ↓
Onboarding (3 steps)
    ↓
Login/Sign Up Screen
    ↓
[After Authentication]
    ↓
Camera Screen
```

### Returning User Flow

```
App Launch
    ↓
Check Authentication
    ↓
[If Authenticated]  →  Camera Screen
[If Not]            →  Login Screen
```

## Screens

### 1. Login Screen (`login_screen.dart`)

**Features:**
- Email/password sign-in form
- Social sign-in buttons (Google, Apple, X)
- "Forgot Password" functionality
- Link to Sign Up screen
- Beautiful gradient design matching brand

**Validation:**
- Email format validation
- Password presence check
- Error messages for failed login

### 2. Sign Up Screen (`signup_screen.dart`)

**Features:**
- Email/password registration
- Full name input
- Password confirmation
- Terms of Service acceptance checkbox
- Links back to login

**Validation:**
- Name required
- Valid email format
- Password minimum 6 characters
- Passwords must match
- Terms must be accepted

### 3. Profile Screen (`profile_screen.dart`)

**Features:**
- Display user information (name, email, photo)
- Show authentication provider
- Account creation and last login dates
- Edit profile (planned)
- Change password (email accounts only)
- Sign out
- Delete account (with confirmation)

**Sections:**
- Profile header with avatar
- Account info
- Account actions
- Danger zone (delete account)

### 4. Camera Screen (Updated)

**Added:**
- Profile access via settings menu
- User avatar display in settings
- Protected route (requires authentication)

## Services

### AuthService (`services/auth_service.dart`)

Main authentication service handling all sign-in/sign-up operations.

**Methods:**

```dart
// Email/Password
Future<UserCredential?> signUpWithEmail({email, password, displayName})
Future<UserCredential?> signInWithEmail({email, password})
Future<void> sendPasswordResetEmail(email)

// Social Sign-In
Future<UserCredential?> signInWithGoogle()
Future<UserCredential?> signInWithApple()
Future<UserCredential?> signInWithTwitter()

// Account Management
Future<void> signOut()
Future<void> deleteAccount()

// Utilities
String getErrorMessage(FirebaseAuthException e)
```

**State Management:**
- Extends `ChangeNotifier` for reactive UI updates
- Provides `authStateChanges` stream
- Notifies listeners on auth state changes

### DatabaseService (`services/database_service.dart`)

Handles all Firestore database operations for user data.

**Methods:**

```dart
Future<void> createUser(UserModel user)
Future<UserModel?> getUser(String uid)
Future<void> updateUser(String uid, Map<String, dynamic> data)
Future<void> updateLastLogin(String uid)
Future<void> deleteUser(String uid)
Stream<UserModel?> streamUser(String uid)
Future<List<UserModel>> getAllUsers()
Future<int> getUsersCount()
```

**Features:**
- Automatic last login tracking
- User metadata support
- Real-time user data streaming
- Admin functions (getAllUsers)

## Models

### UserModel (`models/user_model.dart`)

Data model for user information.

**Fields:**
```dart
String uid
String email
String? displayName
String? photoURL
String? phoneNumber
AuthProvider authProvider
DateTime createdAt
DateTime lastLoginAt
Map<String, dynamic>? metadata
```

**Enums:**
```dart
enum AuthProvider {
  email,
  google,
  apple,
  twitter,
  instagram,
}
```

**Methods:**
- `toFirestore()`: Convert to Firestore document
- `fromFirestore()`: Create from Firestore document
- `fromFirebaseUser()`: Create from Firebase Auth user
- `copyWith()`: Create updated copy

## Security

### Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      // Users can only read/write their own document
      allow read, write: if request.auth != null && 
                            request.auth.uid == userId;
    }
  }
}
```

**Best Practices:**
- User data is isolated per user
- All operations require authentication
- No public read/write access
- Email/password stored securely by Firebase
- OAuth tokens never exposed to client

## Error Handling

### Firebase Auth Errors

The `AuthService` translates Firebase error codes to user-friendly messages:

| Error Code | User Message |
|------------|--------------|
| `weak-password` | The password is too weak |
| `email-already-in-use` | An account already exists with this email |
| `invalid-email` | The email address is invalid |
| `user-not-found` | No account found with this email |
| `wrong-password` | Incorrect password |
| `too-many-requests` | Too many attempts. Please try again later |

### UI Feedback

- ✅ Success: Navigate to next screen
- ❌ Error: SnackBar with error message
- ⏳ Loading: Disabled buttons with loading indicator

## Localization

Authentication strings are localized in `l10n/app_localizations.dart`:

**Supported Languages:**
- English
- French (Français)
- Spanish (Español) - Coming soon
- German (Deutsch) - Coming soon
- Italian (Italiano) - Coming soon

**Key Strings:**
- `sign_in`, `sign_up`, `sign_out`
- `email`, `password`, `full_name`
- `create_account`, `already_have_account`
- `agree_terms`, `forgot_password`

## Future Enhancements

### Planned Features

- [ ] Email verification requirement
- [ ] Phone number authentication
- [ ] Two-factor authentication (2FA)
- [ ] Profile photo upload
- [ ] Edit profile information
- [ ] Account linking (link multiple providers)
- [ ] Social profile sync
- [ ] Activity history
- [ ] Privacy settings
- [ ] Export user data (GDPR compliance)

### Instagram Integration

To add Instagram sign-in:

1. Create Facebook App at [developers.facebook.com](https://developers.facebook.com)
2. Enable Instagram Basic Display API
3. Configure OAuth redirect
4. Add credentials to Firebase

## Testing

### Test Accounts

Create test accounts for each provider:

```dart
// Email test
Email: test@digitizeart.com
Password: Test123456

// Use real accounts for social sign-in testing
```

### Unit Tests (Coming Soon)

```bash
flutter test test/auth_service_test.dart
```

## Analytics

Track authentication events:

- Sign up events (by provider)
- Sign in events
- Failed login attempts
- Sign out events
- Account deletions

Access in: Firebase Console → Analytics → Events

## Maintenance

### Regular Tasks

1. **Monthly:**
   - Review failed authentication attempts
   - Check for suspicious activity
   - Monitor Firebase quotas

2. **Quarterly:**
   - Update dependencies
   - Review security rules
   - Audit user data access

3. **Yearly:**
   - Security audit
   - Clean up inactive accounts
   - Review privacy policy compliance

## Support

### Common Issues

**Issue:** Google Sign-In not working
**Solution:** Check SHA-1 certificate in Firebase Console

**Issue:** Apple Sign-In fails
**Solution:** Verify Apple capability in Xcode

**Issue:** Firestore permission denied
**Solution:** Check security rules and user is authenticated

### Resources

- [Firebase Auth Docs](https://firebase.google.com/docs/auth)
- [FlutterFire Auth](https://firebase.flutter.dev/docs/auth/overview/)
- [Flutter Provider](https://pub.dev/packages/provider)

---

**Built with ❤️ for Digitize.art**
