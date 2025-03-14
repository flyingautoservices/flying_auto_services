import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flying_auto_services/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flying_auto_services/services/user_preferences_service.dart';

class MainProviderState {
  final bool isLoading;
  final bool isUserLoggedIn;
  final UserModel? currentUser;
  final int selectedMainPageIndex;
  final String? errorMessage;

  MainProviderState({
    required this.isLoading,
    required this.isUserLoggedIn,
    this.currentUser,
    required this.selectedMainPageIndex,
    this.errorMessage,
  });

  MainProviderState copyWith({
    bool? isLoading,
    bool? isUserLoggedIn,
    UserModel? currentUser,
    int? selectedMainPageIndex,
    String? errorMessage,
  }) {
    return MainProviderState(
      isLoading: isLoading ?? this.isLoading,
      isUserLoggedIn: isUserLoggedIn ?? this.isUserLoggedIn,
      currentUser: currentUser ?? this.currentUser,
      selectedMainPageIndex:
          selectedMainPageIndex ?? this.selectedMainPageIndex,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class MainProvider extends StateNotifier<MainProviderState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  MainProvider()
    : super(
        MainProviderState(
          isLoading: true,
          isUserLoggedIn: false,
          selectedMainPageIndex: 1, // Default to home page
        ),
      );

  Future<void> getIfUserLoggedIn() async {
    try {
      print('MainProvider: Checking if user is logged in...');

      // First check current state to avoid unnecessary work
      if (state.isUserLoggedIn && state.currentUser != null) {
        print('MainProvider: User already logged in according to state');
        state = state.copyWith(isLoading: false);
        return;
      }

      // Check if user is logged in using SharedPreferences
      final user = await UserPreferencesService.getUser();

      print(
        'MainProvider: User from SharedPreferences: ${user != null ? 'Found' : 'Not found'}',
      );

      if (user != null) {
        print(
          'MainProvider: User found in SharedPreferences, setting logged in state',
        );
        print(
          'MainProvider: User details - ID: ${user.id}, Name: ${user.name}, Role: ${user.role}',
        );

        // Important: Make sure we're updating ALL state properties correctly
        state = state.copyWith(
          isUserLoggedIn: true,
          currentUser: user,
          isLoading: false,
          errorMessage: null, // Clear any previous errors
        );

        print(
          'MainProvider: Updated state - isUserLoggedIn: ${state.isUserLoggedIn}, isLoading: ${state.isLoading}',
        );
      } else {
        print('MainProvider: User not logged in');
        state = state.copyWith(
          isUserLoggedIn: false,
          currentUser: null, // Explicitly set to null
          isLoading: false,
          errorMessage: null, // Clear any previous errors
        );
        print(
          'MainProvider: Updated state - isUserLoggedIn: ${state.isUserLoggedIn}, isLoading: ${state.isLoading}',
        );
      }
    } catch (e) {
      print('MainProvider: Error in getIfUserLoggedIn: $e');
      state = state.copyWith(
        isUserLoggedIn: false,
        currentUser: null, // Explicitly set to null
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  void setIsLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  void setSelectedPage(int index) {
    state = state.copyWith(selectedMainPageIndex: index);
  }

  Future<void> signOut() async {
    try {
      print('MainProvider: Starting logout process');
      state = state.copyWith(isLoading: true);

      // Clear user data from SharedPreferences
      final clearResult = await UserPreferencesService.clearUserData();
      print('MainProvider: SharedPreferences cleared: $clearResult');

      // Reset to a completely fresh state
      state = MainProviderState(
        isLoading: false,
        isUserLoggedIn: false,
        currentUser: null,
        selectedMainPageIndex: 1, // Reset to home page
        errorMessage: null, // Clear any errors
      );

      print('MainProvider: State completely reset after logout');
    } catch (e) {
      print('MainProvider: Error during logout: $e');
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> updateUserProfile(UserModel updatedUser) async {
    try {
      state = state.copyWith(isLoading: true);

      await _firestore
          .collection('users')
          .doc(updatedUser.id)
          .update(updatedUser.copyWith(updatedAt: DateTime.now()).toMap());

      // Update user data in SharedPreferences
      await UserPreferencesService.saveUser(updatedUser);

      state = state.copyWith(currentUser: updatedUser, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final mainProvider = StateNotifierProvider<MainProvider, MainProviderState>((
  ref,
) {
  return MainProvider();
});
