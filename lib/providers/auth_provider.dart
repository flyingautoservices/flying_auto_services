import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flying_auto_services/models/user_model.dart';
import 'package:flying_auto_services/services/user_preferences_service.dart';
import 'package:uuid/uuid.dart';

class AuthState {
  final bool isLoading;
  final String? errorMessage;
  final bool isOtpSent;
  final String? verificationId;
  final int? forceResendingToken;

  AuthState({
    required this.isLoading,
    this.errorMessage,
    required this.isOtpSent,
    this.verificationId,
    this.forceResendingToken,
  });

  AuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isOtpSent,
    String? verificationId,
    int? forceResendingToken,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isOtpSent: isOtpSent ?? this.isOtpSent,
      verificationId: verificationId ?? this.verificationId,
      forceResendingToken: forceResendingToken ?? this.forceResendingToken,
    );
  }
}

class AuthProvider extends StateNotifier<AuthState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // For demo purposes, we'll store OTPs in memory
  // In a real app, you would use a proper SMS service
  final Map<String, String> _otpStore = {};
  
  // Map to associate verification IDs with phone numbers
  final Map<String, String> _verificationPhoneMap = {};

  AuthProvider()
      : super(AuthState(
          isLoading: false,
          isOtpSent: false,
        ));

  Future<void> sendOtp(String phoneNumber) async {
    try {
      print('AuthProvider: Sending OTP to phone number: $phoneNumber');
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      // Ensure the phone number has the 973 Bahrain country code prefix
      if (!phoneNumber.startsWith('973') && !phoneNumber.startsWith('+973')) {
        // Add 973 prefix if it's not already there
        phoneNumber = '973$phoneNumber';
        print('AuthProvider: Added 973 prefix to phone number: $phoneNumber');
      }
      
      // Normalize phone number format
      // If it starts with '+', we'll store it without the '+' prefix
      String normalizedPhoneNumber = phoneNumber;
      if (phoneNumber.startsWith('+')) {
        normalizedPhoneNumber = phoneNumber.substring(1);
        print('AuthProvider: Normalized phone number without + prefix: $normalizedPhoneNumber');
      }

      // Check if phone number exists in Firestore - try both formats
      print('AuthProvider: Checking if phone number exists in Firestore');
      var userQuery = await _firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();
          
      // If no results with the original format, try with the normalized format
      if (userQuery.docs.isEmpty && phoneNumber != normalizedPhoneNumber) {
        print('AuthProvider: No user found with $phoneNumber, trying $normalizedPhoneNumber');
        userQuery = await _firestore
            .collection('users')
            .where('phoneNumber', isEqualTo: normalizedPhoneNumber)
            .limit(1)
            .get();
      }
      
      print('AuthProvider: Found ${userQuery.docs.length} users with this phone number');
      
      // Store the phone number format that matched (if any) for later use
      if (userQuery.docs.isNotEmpty) {
        final userData = userQuery.docs.first.data();
        final storedPhoneNumber = userData['phoneNumber'] as String;
        print('AuthProvider: Found user with phone number: $storedPhoneNumber');
        // Use the format that's actually stored in Firestore
        phoneNumber = storedPhoneNumber;
      }

      // Generate a random 6-digit OTP (in a real app, you would use an SMS service)
      final otp = (1000 + DateTime.now().millisecondsSinceEpoch % 9000).toString();
      
      // Store OTP in memory (in a real app, you would send it via SMS)
      _otpStore[phoneNumber] = otp;
      
      // For demo purposes, print the OTP to console
      print('OTP for $phoneNumber: $otp');

      // Generate a verification ID
      final verificationId = _uuid.v4();
      
      // Associate this verification ID with the phone number
      _verificationPhoneMap[verificationId] = phoneNumber;
      print('AuthProvider: Associated verification ID with phone number: $phoneNumber');

      state = state.copyWith(
        isLoading: false,
        isOtpSent: true,
        verificationId: verificationId,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
        isOtpSent: false,
      );
    }
  }

  Future<UserModel?> verifyOtp(String otp) async {
    try {
      print('AuthProvider: Starting OTP verification');
      state = state.copyWith(isLoading: true, errorMessage: null);

      // In a real app, you would validate the OTP with your SMS service
      // For demo purposes, we'll check against our in-memory store
      
      // Get the phone number from the previous step
      var phoneNumber = await _getPhoneNumberFromVerificationId(state.verificationId!);
      print('AuthProvider: Phone number from verification ID: $phoneNumber');
      
      // Ensure the phone number has the 973 Bahrain country code prefix
      if (phoneNumber != null && !phoneNumber.startsWith('973') && !phoneNumber.startsWith('+973')) {
        // Add 973 prefix if it's not already there
        phoneNumber = '973$phoneNumber';
        print('AuthProvider: Added 973 prefix to phone number: $phoneNumber');
      }
      
      if (phoneNumber == null) {
        print('AuthProvider: Invalid verification session - no phone number found');
        throw Exception('Invalid verification session');
      }
      
      // Check if OTP matches or if it's the master OTP '9999'
      print('AuthProvider: Checking OTP: $otp against stored OTP: ${_otpStore[phoneNumber]} or master OTP: 9999');
      if (_otpStore[phoneNumber] != otp && otp != '9999') {
        print('AuthProvider: Invalid OTP');
        throw Exception('Invalid OTP');
      }
      
      print('AuthProvider: OTP verified successfully');

      // OTP is valid, check if user exists in Firestore
      print('AuthProvider: Checking if user exists in Firestore with phone: $phoneNumber');
      
      // Format the phone number for query - try both with and without the '+' prefix
      String queryPhoneNumber = phoneNumber;
      if (phoneNumber.startsWith('+')) {
        // Also try without the '+' prefix
        queryPhoneNumber = phoneNumber.substring(1);
        print('AuthProvider: Also checking without + prefix: $queryPhoneNumber');
      }
      
      try {
        // First try with the original phone number format
        var userQuery = await _firestore
            .collection('users')
            .where('phoneNumber', isEqualTo: phoneNumber)
            .limit(1)
            .get();
            
        // If no results, try with the alternative format
        if (userQuery.docs.isEmpty && phoneNumber != queryPhoneNumber) {
          print('AuthProvider: No user found with $phoneNumber, trying $queryPhoneNumber');
          userQuery = await _firestore
              .collection('users')
              .where('phoneNumber', isEqualTo: queryPhoneNumber)
              .limit(1)
              .get();
        }

        print('AuthProvider: Firestore query completed. Found ${userQuery.docs.length} documents');

        if (userQuery.docs.isNotEmpty) {
          // User exists, return user data
          final userDoc = userQuery.docs.first;
          final userData = userDoc.data();
          print('AuthProvider: User found in Firestore. ID: ${userDoc.id}, Data: $userData');
          
          final userModel = UserModel.fromMap({...userData, 'id': userDoc.id});
          print('AuthProvider: User model created. Role: ${userModel.role}');
          
          // Save user to shared preferences
          final saveResult = await UserPreferencesService.saveUser(userModel);
          print('AuthProvider: User saved to SharedPreferences: $saveResult');
          
          state = state.copyWith(isLoading: false, isOtpSent: false);
          return userModel;
        } else {
          // New user, return null (registration will be handled separately)
          print('AuthProvider: User not found in Firestore');
          state = state.copyWith(isLoading: false, isOtpSent: false);
          return null;
        }
      } catch (firestoreError) {
        print('AuthProvider: Error querying Firestore: $firestoreError');
        throw Exception('Error checking user data: $firestoreError');
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  // Helper method to get phone number from verification ID
  // In a real app, you would use a proper session management system
  Future<String?> _getPhoneNumberFromVerificationId(String verificationId) async {
    // Return the phone number associated with this verification ID
    final phoneNumber = _verificationPhoneMap[verificationId];
    print('AuthProvider: Retrieved phone number $phoneNumber for verification ID: $verificationId');
    
    if (phoneNumber != null) {
      return phoneNumber;
    }
    
    // Fallback for backward compatibility
    if (_otpStore.isNotEmpty) {
      print('AuthProvider: WARNING - Using fallback method to get phone number');
      return _otpStore.keys.first;
    }
    return null;
  }

  Future<UserModel?> registerUser({
    required String name,
    required String email,
    required String phoneNumber,
    String? city,
    UserRole role = UserRole.customer,
  }) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      // Ensure the phone number has the 973 Bahrain country code prefix
      if (!phoneNumber.startsWith('973') && !phoneNumber.startsWith('+973')) {
        // Add 973 prefix if it's not already there
        phoneNumber = '973$phoneNumber';
        print('AuthProvider: Added 973 prefix to phone number for registration: $phoneNumber');
      }

      // Check if user with this phone number already exists
      final existingUserQuery = await _firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      if (existingUserQuery.docs.isNotEmpty) {
        throw Exception('A user with this phone number already exists');
      }

      // Check if user with this email already exists
      final existingEmailQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (existingEmailQuery.docs.isNotEmpty) {
        throw Exception('A user with this email already exists');
      }

      // Generate a new user ID
      final userId = _uuid.v4();
      final now = DateTime.now();
      
      final userModel = UserModel(
        id: userId,
        name: name,
        email: email,
        phoneNumber: phoneNumber,
        city: city,
        role: role,
        createdAt: now,
        updatedAt: now,
      );

      // Save user data to Firestore
      await _firestore.collection('users').doc(userId).set(userModel.toMap());
      
      // Save user to shared preferences
      await UserPreferencesService.saveUser(userModel);

      state = state.copyWith(isLoading: false);
      return userModel;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  void resetState() {
    state = AuthState(
      isLoading: false,
      isOtpSent: false,
    );
  }
}

final authProvider = StateNotifierProvider<AuthProvider, AuthState>((ref) {
  return AuthProvider();
});
