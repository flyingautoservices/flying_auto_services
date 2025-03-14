# Flying Auto Services App - Widget and Function Documentation

## Table of Contents

1. [Introduction](#introduction)
2. [Core Widgets](#core-widgets)
   - [ServiceProviderProfileModal](#serviceproviderprofilemodal)
   - [Custom Navigation Bars](#custom-navigation-bars)
   - [Authentication Forms](#authentication-forms)
3. [State Management](#state-management)
   - [Riverpod Providers](#riverpod-providers)
   - [State Classes](#state-classes)
4. [Models](#models)
   - [UserModel](#usermodel)
5. [Services](#services)
   - [Authentication](#authentication-services)
   - [URL Launching](#url-launching-services)
6. [Utility Functions](#utility-functions)
   - [Form Validation](#form-validation)
   - [Navigation Helpers](#navigation-helpers)

## Introduction

The Flying Auto Services app is a comprehensive platform for managing automotive services. It supports multiple user roles (customer, employee, admin) with role-specific interfaces and functionality. This document outlines the key widgets, functions, and implementation details that form the foundation of the app.

## Core Widgets

### ServiceProviderProfileModal

A reusable modal that displays comprehensive information about service providers. This widget is designed to be shown from any screen in the app, providing a consistent user experience.

#### Implementation

```dart
class ServiceProviderProfileModal extends StatelessWidget {
  final String name;
  final String phoneNumber;
  final String email;
  final String? location;
  final String? website;
  final String? profileImageUrl;
  final Map<String, String>? socialMediaLinks;
  final List<Map<String, dynamic>>? services;
  final String? notes;
  final String role;

  const ServiceProviderProfileModal({
    super.key,
    required this.name,
    required this.phoneNumber,
    required this.email,
    this.location,
    this.website,
    this.profileImageUrl,
    this.socialMediaLinks,
    this.services,
    this.notes,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle for dragging
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Profile header with image and name
                    _buildProfileHeader(context),
                    const SizedBox(height: 20),
                    
                    // Contact information section
                    _buildSectionTitle('Contact Information'),
                    _buildContactItem(
                      context,
                      icon: Icons.phone,
                      title: 'Phone',
                      value: phoneNumber,
                      onTap: () => _makePhoneCall(phoneNumber),
                      onLongPress: () => _copyToClipboard(context, phoneNumber),
                    ),
                    // Additional contact items...
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
```

#### Key Features

1. **Profile Display**: Shows the service provider's profile image, name, and role.
2. **Contact Information**: Displays phone, email, location, and website with tap actions.
3. **Social Media Links**: Optional section for social media profiles.
4. **Services List**: Displays services offered with pricing and descriptions.
5. **Notes Section**: Shows additional information about the provider.

#### Helper Functions

```dart
// Opens phone dialer with the provider's number
Future<void> _makePhoneCall(String phoneNumber) async {
  final Uri uri = Uri(scheme: 'tel', path: phoneNumber);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  }
}

// Opens email client with the provider's email
Future<void> _sendEmail(String email) async {
  final Uri uri = Uri(scheme: 'mailto', path: email);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  }
}

// Opens map application with the provider's address
Future<void> _openMap(String address) async {
  final Uri uri = Uri.parse('https://maps.google.com/?q=$address');
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  }
}

// Opens a URL in the browser
Future<void> _openUrl(String url) async {
  if (!url.startsWith('http://') && !url.startsWith('https://')) {
    url = 'https://$url';
  }
  
  final Uri uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

// Copies text to clipboard and shows a snackbar confirmation
void _copyToClipboard(BuildContext context, String text) {
  Clipboard.setData(ClipboardData(text: text));
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Copied to clipboard')),
  );
}
```

#### Usage Example

```dart
void showServiceProviderProfile(BuildContext context, UserModel provider) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => ServiceProviderProfileModal(
      name: provider.name,
      phoneNumber: provider.phoneNumber,
      email: provider.email,
      location: provider.city,
      role: provider.role.toString().split('.').last,
      profileImageUrl: provider.profileImageUrl,
    ),
  );
}
```

### Custom Navigation Bars

The app implements role-specific navigation bars to provide tailored experiences for different user types.

#### Implementation

```dart
Widget _buildNavBar(UserModel? user) {
  if (user == null) return const SizedBox();

  // Different navigation bars based on user role
  switch (user.role) {
    case UserRole.customer:
      return _buildCustomerNavBar();
    case UserRole.employee:
      return _buildEmployeeNavBar();
    case UserRole.admin:
      return _buildAdminNavBar();
  }
}

// Navigation bar for customers
Widget _buildCustomerNavBar() {
  final mainProviderData = ref.watch(mainProvider);

  return Padding(
    padding: const EdgeInsets.all(20.0),
    child: Container(
      width: double.infinity,
      height: 80,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
          topLeft: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            Icons.calendar_today,
            0,
            mainProviderData,
            'Bookings',
          ),
          _buildNavItem(Icons.home, 1, mainProviderData, 'Home'),
          _buildNavItem(Icons.car_repair, 2, mainProviderData, 'Services'),
          _buildNavItem(Icons.person, 3, mainProviderData, 'Profile'),
        ],
      ),
    ),
  );
}
```

#### Key Features

1. **Role-Based Navigation**: Different navigation options for customers, employees, and admins.
2. **Custom Styling**: Attractive UI with rounded corners and shadow effects.
3. **Active Item Indication**: Visual feedback for the currently selected tab.
4. **Consistent Experience**: Maintains a unified design language across different user roles.

### Authentication Forms

The app provides a comprehensive authentication system with login and registration forms.

#### Implementation

```dart
Widget _buildLoginForm(AuthState authState) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Column(
      children: [
        // Phone number input
        _buildInputField(
          controller: _phoneController,
          hintText: 'Phone number',
          prefixIcon: Icons.phone,
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your phone number';
            }
            return null;
          },
        ),
        const SizedBox(height: 10),
        Text(
          'You can log in using your phone number by verifying an OTP',
          style: TextStyle(color: Colors.white, fontSize: 12),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),

        // Login button
        _buildAuthButton(
          text: 'Login',
          isLoading: authState.isLoading,
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              String phoneNumber = _phoneController.text.trim();
              
              // Ensure the phone number has the country code prefix
              if (!phoneNumber.startsWith('973') && !phoneNumber.startsWith('+973')) {
                phoneNumber = '973$phoneNumber';
              }
              
              // Add + prefix if needed for international format
              if (!phoneNumber.startsWith('+')) {
                phoneNumber = '+$phoneNumber';
              }
              
              ref.read(authProvider.notifier).sendOtp(phoneNumber);
            }
          },
        ),
      ],
    ),
  );
}

Widget _buildInputField({
  required TextEditingController controller,
  required String hintText,
  required IconData prefixIcon,
  TextInputType? keyboardType,
  bool obscureText = false,
  String? Function(String?)? validator,
}) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(10),
    ),
    child: TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        prefixIcon: Icon(prefixIcon, color: Colors.white),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      ),
      style: const TextStyle(color: Colors.white),
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
    ),
  );
}
```

#### Key Features

1. **OTP Authentication**: Phone-based authentication using one-time passwords.
2. **Form Validation**: Input validation for all form fields.
3. **Toggle Between Login/Register**: Easy switching between authentication modes.
4. **Custom Input Fields**: Styled input fields with icons and validation.
5. **Loading States**: Visual feedback during authentication processes.

## State Management

### Riverpod Providers

The app uses Riverpod for state management, providing a clean and efficient way to manage application state.

#### Main Provider

```dart
final mainProvider = StateNotifierProvider<MainProviderNotifier, MainProviderState>((ref) {
  return MainProviderNotifier(ref);
});

class MainProviderState {
  final bool isLoading;
  final bool isUserLoggedIn;
  final UserModel? currentUser;
  final int selectedMainPageIndex;

  MainProviderState({
    this.isLoading = true,
    this.isUserLoggedIn = false,
    this.currentUser,
    this.selectedMainPageIndex = 1, // Default to home tab
  });

  MainProviderState copyWith({
    bool? isLoading,
    bool? isUserLoggedIn,
    UserModel? currentUser,
    int? selectedMainPageIndex,
  }) {
    return MainProviderState(
      isLoading: isLoading ?? this.isLoading,
      isUserLoggedIn: isUserLoggedIn ?? this.isUserLoggedIn,
      currentUser: currentUser ?? this.currentUser,
      selectedMainPageIndex: selectedMainPageIndex ?? this.selectedMainPageIndex,
    );
  }
}

class MainProviderNotifier extends StateNotifier<MainProviderState> {
  final Ref _ref;

  MainProviderNotifier(this._ref) : super(MainProviderState());

  void setIsLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  void setSelectedIndex(int index) {
    state = state.copyWith(selectedMainPageIndex: index);
  }

  Future<void> getIfUserLoggedIn() async {
    try {
      final authService = await _ref.read(authServiceFutureProvider.future);
      final user = await authService.getCurrentUser();
      
      if (user != null) {
        state = state.copyWith(
          isUserLoggedIn: true,
          currentUser: user,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isUserLoggedIn: false,
          currentUser: null,
          isLoading: false,
        );
      }
    } catch (e) {
      print('Error checking if user is logged in: $e');
      state = state.copyWith(
        isUserLoggedIn: false,
        currentUser: null,
        isLoading: false,
      );
    }
  }

  Future<void> logout() async {
    try {
      final authService = await _ref.read(authServiceFutureProvider.future);
      await authService.signOut();
      state = state.copyWith(
        isUserLoggedIn: false,
        currentUser: null,
      );
    } catch (e) {
      print('Error logging out: $e');
    }
  }
}
```

### Auth Provider

```dart
final authProvider = StateNotifierProvider<AuthProviderNotifier, AuthState>((ref) {
  return AuthProviderNotifier(ref);
});

class AuthState {
  final bool isLoading;
  final bool isOtpSent;
  final String? verificationId;
  final String? error;

  AuthState({
    this.isLoading = false,
    this.isOtpSent = false,
    this.verificationId,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isOtpSent,
    String? verificationId,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isOtpSent: isOtpSent ?? this.isOtpSent,
      verificationId: verificationId ?? this.verificationId,
      error: error,
    );
  }
}
```

## Models

### UserModel

The `UserModel` class represents a user in the application with various attributes and helper methods.

```dart
enum UserRole {
  customer,
  employee,
  admin,
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String? city;
  final UserRole role;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    this.city,
    required this.role,
    this.profileImageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    String? city,
    UserRole? role,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      city: city ?? this.city,
      role: role ?? this.role,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'city': city,
      'role': role.toString().split('.').last,
      'profileImageUrl': profileImageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      city: map['city'],
      role: _parseUserRole(map['role'] ?? 'customer'),
      profileImageUrl: map['profileImageUrl'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

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
}
```

#### Key Features

1. **Role-Based Access**: Enum for different user roles (customer, employee, admin).
2. **Serialization**: Methods to convert between Firestore documents and model objects.
3. **Immutability**: Immutable class with copyWith method for updates.
4. **Type Safety**: Strong typing for all user attributes.

## Services

### Authentication Services

The app uses Firebase Authentication for user management, with a custom service layer to handle authentication logic.

```dart
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserPreferencesService _prefsService;

  AuthService(this._prefsService);

  // Get the current user from Firebase
  Future<UserModel?> getCurrentUser() async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) return null;

      // Get user data from Firestore
      final userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();
      if (userDoc.exists) {
        return UserModel.fromMap(userDoc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  // Sign in with phone number and OTP
  Future<void> verifyOtp({
    required String verificationId,
    required String otp,
    required Function(UserModel) onSuccess,
    required Function(String) onError,
  }) async {
    try {
      // Create credential
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      // Sign in with credential
      final userCredential = await _auth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        // Check if user exists in Firestore
        final userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();
        
        if (userDoc.exists) {
          // User exists, return user model
          final userModel = UserModel.fromMap(userDoc.data()!);
          await _prefsService.saveUserData(userModel);
          onSuccess(userModel);
        } else {
          // User doesn't exist, sign out
          await _auth.signOut();
          onError('User not found. Please register first.');
        }
      }
    } catch (e) {
      onError('Invalid OTP. Please try again.');
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    await _prefsService.clearUserData();
  }
}
```

### URL Launching Services

The app uses the `url_launcher` package to handle external actions like making phone calls, sending emails, and opening maps.

```dart
// Opens phone dialer with the provider's number
Future<void> _makePhoneCall(String phoneNumber) async {
  final Uri uri = Uri(scheme: 'tel', path: phoneNumber);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  }
}

// Opens email client with the provider's email
Future<void> _sendEmail(String email) async {
  final Uri uri = Uri(scheme: 'mailto', path: email);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  }
}

// Opens map application with the provider's address
Future<void> _openMap(String address) async {
  final Uri uri = Uri.parse('https://maps.google.com/?q=$address');
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  }
}

// Opens a URL in the browser
Future<void> _openUrl(String url) async {
  if (!url.startsWith('http://') && !url.startsWith('https://')) {
    url = 'https://$url';
  }
  
  final Uri uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
```

## Utility Functions

### Form Validation

The app includes various form validation functions to ensure data integrity.

```dart
// Phone number validation
String? validatePhoneNumber(String? value) {
  if (value == null || value.isEmpty) {
    return 'Please enter your phone number';
  }
  // Simple regex for phone number validation
  if (!RegExp(r'^[0-9]{8,}$').hasMatch(value.replaceAll(RegExp(r'[^0-9]'), ''))) {
    return 'Please enter a valid phone number';
  }
  return null;
}

// Email validation
String? validateEmail(String? value) {
  if (value == null || value.isEmpty) {
    return 'Please enter your email';
  }
  if (!value.contains('@') || !value.contains('.')) {
    return 'Please enter a valid email address';
  }
  return null;
}

// Name validation
String? validateName(String? value) {
  if (value == null || value.isEmpty) {
    return 'Please enter your name';
  }
  if (value.length < 2) {
    return 'Name must be at least 2 characters';
  }
  return null;
}
```

### Navigation Helpers

Helper functions to simplify navigation throughout the app.

```dart
// Navigate to a new screen
void navigateTo(BuildContext context, Widget screen) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => screen),
  );
}

// Navigate to a new screen and remove all previous screens
void navigateAndReplace(BuildContext context, Widget screen) {
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (context) => screen),
    (route) => false,
  );
}

// Navigate to a named route
void navigateToNamed(BuildContext context, String routeName, {Object? arguments}) {
  Navigator.pushNamed(context, routeName, arguments: arguments);
}

// Show a modal bottom sheet
void showBottomModal(BuildContext context, Widget widget) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => widget,
  );
}
```

## Conclusion

This documentation covers the main widgets and functions used in the Flying Auto Services app. These components form the foundation of the app's architecture and can be reused and extended as needed for future development. The app follows best practices for Flutter development, including:

1. **Separation of Concerns**: Clear separation between UI, business logic, and data layers.
2. **Reusable Components**: Widgets designed for reusability across the app.
3. **State Management**: Efficient state management using Riverpod.
4. **Error Handling**: Comprehensive error handling throughout the app.
5. **User Experience**: Focus on providing a smooth and intuitive user experience.
