import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'database_service.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final DatabaseService _databaseService = DatabaseService();

  User? get currentUser => _auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Email & Password Sign Up
  Future<UserCredential?> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name if provided
      if (displayName != null && credential.user != null) {
        await credential.user!.updateDisplayName(displayName);
      }

      // Create user document in Firestore
      if (credential.user != null) {
        final userModel = UserModel.fromFirebaseUser(
          credential.user!.uid,
          email,
          AuthProvider.email,
          displayName: displayName ?? credential.user!.displayName,
        );
        await _databaseService.createUser(userModel);
      }

      notifyListeners();
      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint('Sign up error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  // Email & Password Sign In
  Future<UserCredential?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update last login
      if (credential.user != null) {
        await _databaseService.updateLastLogin(credential.user!.uid);
      }

      notifyListeners();
      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint('Sign in error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  // Google Sign In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger Google Sign In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled
        return null;
      }

      // Obtain auth details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final userCredential = await _auth.signInWithCredential(credential);

      // Create or update user document
      if (userCredential.user != null) {
        final existingUser =
            await _databaseService.getUser(userCredential.user!.uid);

        if (existingUser == null) {
          // New user - create profile
          final userModel = UserModel.fromFirebaseUser(
            userCredential.user!.uid,
            userCredential.user!.email!,
            AuthProvider.google,
            displayName: userCredential.user!.displayName,
            photoURL: userCredential.user!.photoURL,
          );
          await _databaseService.createUser(userModel);
        } else {
          // Existing user - update last login
          await _databaseService.updateLastLogin(userCredential.user!.uid);
        }
      }

      notifyListeners();
      return userCredential;
    } catch (e) {
      debugPrint('Google sign in error: $e');
      rethrow;
    }
  }

  // Apple Sign In
  Future<UserCredential?> signInWithApple() async {
    try {
      // Request Apple ID credential
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Create OAuth credential
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Sign in to Firebase
      final userCredential = await _auth.signInWithCredential(oauthCredential);

      // Create or update user document
      if (userCredential.user != null) {
        final existingUser =
            await _databaseService.getUser(userCredential.user!.uid);

        if (existingUser == null) {
          // New user - create profile
          String? displayName;
          if (appleCredential.givenName != null ||
              appleCredential.familyName != null) {
            displayName =
                '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'
                    .trim();
          }

          final userModel = UserModel.fromFirebaseUser(
            userCredential.user!.uid,
            userCredential.user!.email ?? appleCredential.email ?? '',
            AuthProvider.apple,
            displayName: displayName ?? userCredential.user!.displayName,
          );
          await _databaseService.createUser(userModel);
        } else {
          // Existing user - update last login
          await _databaseService.updateLastLogin(userCredential.user!.uid);
        }
      }

      notifyListeners();
      return userCredential;
    } catch (e) {
      debugPrint('Apple sign in error: $e');
      rethrow;
    }
  }

  // Twitter/X Sign In
  Future<UserCredential?> signInWithTwitter() async {
    try {
      final twitterProvider = TwitterAuthProvider();
      final userCredential = await _auth.signInWithProvider(twitterProvider);

      // Create or update user document
      if (userCredential.user != null) {
        final existingUser =
            await _databaseService.getUser(userCredential.user!.uid);

        if (existingUser == null) {
          final userModel = UserModel.fromFirebaseUser(
            userCredential.user!.uid,
            userCredential.user!.email ?? '',
            AuthProvider.twitter,
            displayName: userCredential.user!.displayName,
            photoURL: userCredential.user!.photoURL,
          );
          await _databaseService.createUser(userModel);
        } else {
          await _databaseService.updateLastLogin(userCredential.user!.uid);
        }
      }

      notifyListeners();
      return userCredential;
    } catch (e) {
      debugPrint('Twitter sign in error: $e');
      rethrow;
    }
  }

  // Password Reset
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      debugPrint('Password reset error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      notifyListeners();
    } catch (e) {
      debugPrint('Sign out error: $e');
      rethrow;
    }
  }

  // Delete Account
  Future<void> deleteAccount() async {
    try {
      if (currentUser != null) {
        await _databaseService.deleteUser(currentUser!.uid);
        await currentUser!.delete();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Delete account error: $e');
      rethrow;
    }
  }

  // Get error message from FirebaseAuthException
  String getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password is too weak.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
