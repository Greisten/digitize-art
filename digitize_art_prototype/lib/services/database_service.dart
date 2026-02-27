import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _usersCollection => _firestore.collection('users');

  // Create new user
  Future<void> createUser(UserModel user) async {
    try {
      await _usersCollection.doc(user.uid).set(user.toFirestore());
      debugPrint('User created: ${user.uid}');
    } catch (e) {
      debugPrint('Error creating user: $e');
      rethrow;
    }
  }

  // Get user by UID
  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user: $e');
      rethrow;
    }
  }

  // Update user
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      await _usersCollection.doc(uid).update(data);
      debugPrint('User updated: $uid');
    } catch (e) {
      debugPrint('Error updating user: $e');
      rethrow;
    }
  }

  // Update last login timestamp
  Future<void> updateLastLogin(String uid) async {
    try {
      await _usersCollection.doc(uid).update({
        'lastLoginAt': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('Error updating last login: $e');
      rethrow;
    }
  }

  // Delete user
  Future<void> deleteUser(String uid) async {
    try {
      await _usersCollection.doc(uid).delete();
      debugPrint('User deleted: $uid');
    } catch (e) {
      debugPrint('Error deleting user: $e');
      rethrow;
    }
  }

  // Stream user data
  Stream<UserModel?> streamUser(String uid) {
    return _usersCollection.doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    });
  }

  // Get all users (admin function - should be restricted in production)
  Future<List<UserModel>> getAllUsers() async {
    try {
      final querySnapshot = await _usersCollection.get();
      return querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting all users: $e');
      rethrow;
    }
  }

  // Get users count
  Future<int> getUsersCount() async {
    try {
      final querySnapshot = await _usersCollection.count().get();
      return querySnapshot.count;
    } catch (e) {
      debugPrint('Error getting users count: $e');
      return 0;
    }
  }

  // Search users by email
  Future<List<UserModel>> searchUsersByEmail(String email) async {
    try {
      final querySnapshot = await _usersCollection
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      return querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error searching users: $e');
      rethrow;
    }
  }

  // Update user metadata
  Future<void> updateUserMetadata(
    String uid,
    Map<String, dynamic> metadata,
  ) async {
    try {
      await _usersCollection.doc(uid).update({
        'metadata': metadata,
      });
    } catch (e) {
      debugPrint('Error updating metadata: $e');
      rethrow;
    }
  }
}
