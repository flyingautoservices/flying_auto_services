import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:restart_app/restart_app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flying_auto_services/firebase_options.dart';
import 'package:flying_auto_services/providers/main_provider.dart';
import 'package:flying_auto_services/screens/main_navigation.dart';
import 'package:flying_auto_services/screens/splash_screen.dart';
import 'package:flying_auto_services/services/auth_service.dart';
import 'package:flying_auto_services/services/shared_preferences_service.dart';
import 'package:flying_auto_services/utils/app_theme.dart';

import 'screens/auth/auth_page.dart';

// Global error handler
void _handleError(Object error, StackTrace stack) {
  print('Uncaught error: $error');
  print('Stack trace: $stack');
}

void main() async {
  // Set up global error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    print('Flutter error: ${details.exception}');
    print('Stack trace: ${details.stack}');
  };

  WidgetsFlutterBinding.ensureInitialized();

  // Handle errors in async code
  PlatformDispatcher.instance.onError = (error, stack) {
    _handleError(error, stack);
    return true; // Prevent the error from propagating
  };

  try {
    // Initialize Firebase with options
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  
  } catch (e) {
    print('Error initializing Firebase: $e');
    // Continue app initialization even if Firebase fails to initialize
    print('App will run without Firebase functionality');
  }

  // Initialize services
  final container = ProviderContainer();
  try {
    print('Main: Starting service initialization...');
    // Initialize SharedPreferences first
    await container.read(sharedPreferencesServiceFutureProvider.future);
    print('Main: SharedPreferences service initialized');

    // Initialize auth service
    await container.read(authServiceFutureProvider.future);
    print('Main: Auth service initialized');
    
    // Manually initialize MainProvider to ensure it's ready
    print('Main: Initializing MainProvider...');
    final mainProviderNotifier = container.read(mainProvider.notifier);
    print('Main: MainProvider initialized, setting loading to false');
    mainProviderNotifier.setIsLoading(false);
  } catch (e, stack) {
    print('Main: Error initializing services: $e');
    print('Main: Stack trace: $stack');
    // Show error screen instead of crashing
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to Initialize App',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Error: $e',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Restart app
                      Restart.restartApp();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return; // Don't proceed with normal app initialization
  }

  runApp(ProviderScope(parent: container, child: const MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    print('_MyAppState: initState called');
    // Initialize user state when app starts - no delay to ensure it happens immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('_MyAppState: Post frame callback - checking user login state');
      ref.read(mainProvider.notifier).getIfUserLoggedIn();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch app state
    final appState = ref.watch(mainProvider);

    return MaterialApp(
      title: 'Flying Auto Services',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home:
          appState.isLoading
              ? const SplashScreen()
              : appState.isUserLoggedIn
              ? const MainNavigationPage()
              : const AuthPage(),
      routes: {
        '/auth': (context) => const AuthPage(),
        '/home': (context) => const MainNavigationPage(),
      },
    );
  }
}
