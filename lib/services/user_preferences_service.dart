import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flying_auto_services/models/user_model.dart';

class UserPreferencesService {
  static const String _userKey = 'user_data';
  static const String _authTokenKey = 'auth_token';

  // Save user data to shared preferences
  static Future<bool> saveUser(UserModel user) async {
    try {
      print('UserPreferencesService: Saving user to SharedPreferences: ${user.id}, ${user.name}, ${user.phoneNumber}, role: ${user.role}');
      final prefs = await SharedPreferences.getInstance();
      
      // Create a serializable map from the user model
      // We need to manually convert Timestamp objects to ISO strings
      final Map<String, dynamic> serializableData = {
        'id': user.id,
        'name': user.name,
        'email': user.email,
        'phoneNumber': user.phoneNumber,
        'city': user.city,
        'role': user.role.toString().split('.').last,
        'profileImageUrl': user.profileImageUrl,
        'createdAt': user.createdAt.toIso8601String(),
        'updatedAt': user.updatedAt.toIso8601String(),
      };
      
      print('UserPreferencesService: Serializable data map: $serializableData');
      final jsonData = jsonEncode(serializableData);
      print('UserPreferencesService: JSON encoded data length: ${jsonData.length}');
      final result = await prefs.setString(_userKey, jsonData);
      print('UserPreferencesService: Save result: $result');
      return result;
    } catch (e) {
      print('UserPreferencesService: Error saving user data: $e');
      return false;
    }
  }

  // Get user data from shared preferences
  static Future<UserModel?> getUser() async {
    try {
      print('UserPreferencesService: Getting user from SharedPreferences');
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString(_userKey);
      
      if (userString != null) {
        print('UserPreferencesService: Found user string in SharedPreferences, length: ${userString.length}');
        try {
          final userData = jsonDecode(userString) as Map<String, dynamic>;
          print('UserPreferencesService: Successfully decoded user data: $userData');
          
          // Convert ISO date strings back to DateTime objects
          final Map<String, dynamic> convertedData = {...userData};
          if (userData['createdAt'] != null) {
            convertedData['createdAt'] = DateTime.parse(userData['createdAt']);
          }
          if (userData['updatedAt'] != null) {
            convertedData['updatedAt'] = DateTime.parse(userData['updatedAt']);
          }
          
          final user = UserModel(
            id: convertedData['id'] ?? '',
            name: convertedData['name'] ?? '',
            email: convertedData['email'] ?? '',
            phoneNumber: convertedData['phoneNumber'] ?? '',
            city: convertedData['city'],
            role: _parseUserRole(convertedData['role'] ?? 'customer'),
            profileImageUrl: convertedData['profileImageUrl'],
            createdAt: convertedData['createdAt'] ?? DateTime.now(),
            updatedAt: convertedData['updatedAt'] ?? DateTime.now(),
          );
          
          print('UserPreferencesService: Created user model: ${user.id}, ${user.name}, role: ${user.role}');
          return user;
        } catch (parseError) {
          print('UserPreferencesService: Error parsing user data: $parseError');
          // Clear invalid data
          await prefs.remove(_userKey);
          return null;
        }
      }
      print('UserPreferencesService: No user data found in SharedPreferences');
      return null;
    } catch (e) {
      print('UserPreferencesService: Error getting user data: $e');
      return null;
    }
  }
  
  // Helper method to parse user role from string
  static UserRole _parseUserRole(String role) {
    switch (role) {
      case 'admin':
        return UserRole.admin;
      case 'employee':
        return UserRole.employee;
      case 'customer':
      default:
        return UserRole.customer;
    }
  }

  // Save authentication token (for future use with JWT if needed)
  static Future<bool> saveAuthToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_authTokenKey, token);
    } catch (e) {
      print('Error saving auth token: $e');
      return false;
    }
  }

  // Get authentication token
  static Future<String?> getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_authTokenKey);
    } catch (e) {
      print('Error getting auth token: $e');
      return null;
    }
  }
  


  // Clear all user data (logout)
  static Future<bool> clearUserData() async {
    try {
      print('UserPreferencesService: Starting complete logout and data clearing');
      final prefs = await SharedPreferences.getInstance();
      
      // Clear specific keys
      final userResult = await prefs.remove(_userKey);
      print('UserPreferencesService: Cleared user data: $userResult');
      
      final tokenResult = await prefs.remove(_authTokenKey);
      print('UserPreferencesService: Cleared auth token: $tokenResult');
      
      // For a complete logout, you might want to clear ALL preferences
      // Uncomment the following line to clear everything (use with caution)
      // await prefs.clear();
      // print('UserPreferencesService: Cleared ALL SharedPreferences data');
      
      return true;
    } catch (e) {
      print('UserPreferencesService: Error clearing user data: $e');
      return false;
    }
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_userKey);
    } catch (e) {
      print('Error checking login status: $e');
      return false;
    }
  }
}
