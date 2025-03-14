import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flying_auto_services/models/user_model.dart';
import 'package:flying_auto_services/services/user_preferences_service.dart';
import 'package:uuid/uuid.dart';

class AuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // Check if user is logged in (based on local storage)
  Future<bool> get isLoggedIn async {
    final user = await UserPreferencesService.getUser();
    return user != null;
  }

  // Register a new user
  Future<UserModel> registerUser({
    required String name,
    required String phoneNumber,
    String? email,
    String? city,
  }) async {
    try {
      // Generate a unique ID for the user
      final String uid = _uuid.v4();
      
      final userData = {
        'id': uid,
        'name': name,
        'phoneNumber': phoneNumber,
        'email': email,
        'city': city,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Create user document in Firestore
      await _firestore.collection('users').doc(uid).set(userData);
      
      // Get the user data with server timestamps
      final userDoc = await _firestore.collection('users').doc(uid).get();
      final userModel = UserModel.fromMap({
        ...userDoc.data()!,
        'id': uid,
      });
      
      // Save user to local storage
      await UserPreferencesService.saveUser(userModel);
      
      return userModel;
    } catch (e) {
      print('Error registering user: $e');
      rethrow;
    }
  }

  // Login user with phone number
  Future<UserModel?> loginWithPhone({
    required String phoneNumber,
  }) async {
    try {
      // Query Firestore for user with this phone number
      final querySnapshot = await _firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        // No user found with this phone number
        return null;
      }
      
      // User found, create UserModel from document
      final userDoc = querySnapshot.docs.first;
      final userModel = UserModel.fromMap(userDoc.data());
      
      // Save user to local storage
      await UserPreferencesService.saveUser(userModel);
      
      return userModel;
    } catch (e) {
      print('Error logging in user: $e');
      rethrow;
    }
  }

  // Get current user from local storage
  Future<UserModel?> getCurrentUser() async {
    return await UserPreferencesService.getUser();
  }

  // Update user profile
  Future<UserModel> updateUserProfile({
    required UserModel user,
    String? name,
    String? email,
    String? city,
  }) async {
    try {
      final updatedData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (name != null) updatedData['name'] = name;
      if (email != null) updatedData['email'] = email;
      if (city != null) updatedData['city'] = city;
      
      // Update Firestore document
      await _firestore.collection('users').doc(user.id).update(updatedData);
      
      // Get updated user data
      final userDoc = await _firestore.collection('users').doc(user.id).get();
      final updatedUser = UserModel.fromMap(userDoc.data()!);
      
      // Update local storage
      await UserPreferencesService.saveUser(updatedUser);
      
      return updatedUser;
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await UserPreferencesService.clearUserData();
  }

  // Initialize service
  Future<void> initialize() async {
    // Any initialization logic can go here
    print('Auth service initialized');
  }
}

// Provider for AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Future provider for initialization
final authServiceFutureProvider = FutureProvider<void>((ref) async {
  final authService = ref.read(authServiceProvider);
  return await authService.initialize();
});
