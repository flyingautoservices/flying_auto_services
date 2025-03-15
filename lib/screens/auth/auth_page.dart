import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../providers/main_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/custom_app_bar.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  bool _isLogin = true;
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _cityController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const CustomAppBar(
        showLogo: true,
        centerTitle: true,
        actions: [],
      ),
      body: SingleChildScrollView(
        child: Container(
          height: size.height,
          width: size.width,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/background.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // We've removed the logo container since we're using the app bar
                const SizedBox(height: 30),

                // Form fields
                if (authState.isOtpSent)
                  _buildOtpForm(authState)
                else
                  _isLogin
                      ? _buildLoginForm(authState)
                      : _buildRegisterForm(authState),

                // Toggle login/register
                const SizedBox(height: 20),
                if (!authState.isOtpSent) _buildToggleAuthMode(),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
                
                // Ensure the phone number has the 973 Bahrain country code prefix
                if (!phoneNumber.startsWith('973') && !phoneNumber.startsWith('+973')) {
                  // Add 973 prefix if it's not already there
                  phoneNumber = '973$phoneNumber';
                  print('AuthPage: Added 973 prefix to phone number: $phoneNumber');
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

  Widget _buildRegisterForm(AuthState authState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Name input
          _buildInputField(
            controller: _nameController,
            hintText: 'Name',
            prefixIcon: Icons.person,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),

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

          // Email input
          _buildInputField(
            controller: _emailController,
            hintText: 'Email',
            prefixIcon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!value.contains('@')) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),

          // City input
          _buildInputField(
            controller: _cityController,
            hintText: 'City',
            prefixIcon: Icons.location_city,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your city';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Register button
          _buildAuthButton(
            text: 'Sign Up',
            isLoading: authState.isLoading,
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                String phoneNumber = _phoneController.text.trim();
                
                // Ensure the phone number has the 973 Bahrain country code prefix
                if (!phoneNumber.startsWith('973') && !phoneNumber.startsWith('+973')) {
                  // Add 973 prefix if it's not already there
                  phoneNumber = '973$phoneNumber';
                  print('AuthPage: Added 973 prefix to phone number: $phoneNumber');
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

  Widget _buildOtpForm(AuthState authState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // OTP input
          _buildInputField(
            controller: _otpController,
            hintText: 'Enter OTP',
            prefixIcon: Icons.lock,
            keyboardType: TextInputType.number,
            maxLength: 4,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the OTP';
              }
              if (value.length < 4) {
                return 'OTP must be 4 digits';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Verify button
          _buildAuthButton(
            text: 'Verify',
            isLoading: authState.isLoading,
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final otp = _otpController.text.trim();
                print('Auth Page: Verifying OTP: $otp');
                
                final user = await ref
                    .read(authProvider.notifier)
                    .verifyOtp(otp);

                print('Auth Page: OTP verification result: ${user != null ? 'User found' : 'User not found'}');
                
                if (user != null) {
                  // User exists, update main provider
                  print('Auth Page: Existing user, updating login state');
                  await ref.read(mainProvider.notifier).getIfUserLoggedIn();
                  print('Auth Page: Login state updated');
                } else if (!_isLogin) {
                  // New user, register
                  print('Auth Page: New user, registering');
                  final newUser = await ref
                      .read(authProvider.notifier)
                      .registerUser(
                        name: _nameController.text.trim(),
                        email: _emailController.text.trim(),
                        phoneNumber: _phoneController.text.trim(),
                        city: _cityController.text.trim(),
                      );

                  print('Auth Page: Registration result: ${newUser != null ? 'Success' : 'Failed'}');
                  
                  if (newUser != null) {
                    // Registration successful, update main provider
                    print('Auth Page: Registration successful, updating login state');
                    await ref.read(mainProvider.notifier).getIfUserLoggedIn();
                    print('Auth Page: Login state updated after registration');
                  }
                } else {
                  // Login failed - this is the case we need to handle
                  print('Auth Page: Login failed - user not found and not in registration mode');
                  // Show error message to user
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Login failed. Please register first or check your phone number.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
          const SizedBox(height: 10),

          // Resend OTP
          TextButton(
            onPressed:
                authState.isLoading
                    ? null
                    : () {
                      String phoneNumber = _phoneController.text.trim();
                      
                      // Ensure the phone number has the 973 Bahrain country code prefix
                      if (!phoneNumber.startsWith('973') && !phoneNumber.startsWith('+973')) {
                        // Add 973 prefix if it's not already there
                        phoneNumber = '973$phoneNumber';
                        print('AuthPage: Added 973 prefix to phone number: $phoneNumber');
                      }
                      
                      // Add + prefix if needed for international format
                      if (!phoneNumber.startsWith('+')) {
                        phoneNumber = '+$phoneNumber';
                      }
                      
                      ref.read(authProvider.notifier).sendOtp(phoneNumber);
                    },
            child: Text(
              'Resend OTP',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Back button
          TextButton(
            onPressed:
                authState.isLoading
                    ? null
                    : () {
                      ref.read(authProvider.notifier).resetState();
                    },
            child: Text('Back to Login', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLength: maxLength,
        decoration: InputDecoration(
          fillColor: Colors.white.withOpacity(0.05),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.white, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.white, width: 1),
          ),
          hintText: hintText,
          prefixIcon: Icon(prefixIcon, color: AppColor.primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
          counterText: '',
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildAuthButton({
    required String text,
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColor.primary,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 5,
        ),
        child:
            isLoading
                ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColor.primary,
                  ),
                )
                : Text(
                  text,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
      ),
    );
  }

  Widget _buildToggleAuthMode() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isLogin ? 'Don\'t have an account?' : 'Already have an account?',
          style: TextStyle(color: Colors.white),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _isLogin = !_isLogin;
            });
          },
          child: Text(
            _isLogin ? 'Sign up here' : 'Sign in here',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
