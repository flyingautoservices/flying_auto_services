import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flying_auto_services/models/user_model.dart';
import 'package:flying_auto_services/providers/main_provider.dart';
import 'package:flying_auto_services/screens/admin/services_management_screen.dart';
import 'package:flying_auto_services/screens/admin/employees_management_screen.dart';
import 'package:flying_auto_services/screens/auth/auth_page.dart';
import 'package:flying_auto_services/screens/customer/customer_home_screen.dart';
import 'package:flying_auto_services/screens/customer/customer_orders_screen.dart';
import 'package:flying_auto_services/screens/employee/employee_service_requests_screen.dart';
import 'package:flying_auto_services/screens/profile/profile_screen.dart';
import 'package:flying_auto_services/utils/app_theme.dart';

class MainNavigationPage extends ConsumerStatefulWidget {
  const MainNavigationPage({super.key});

  @override
  ConsumerState<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends ConsumerState<MainNavigationPage> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      await ref.read(mainProvider.notifier).getIfUserLoggedIn();
      if (mounted) ref.read(mainProvider.notifier).setIsLoading(false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final mainProviderData = ref.watch(mainProvider);
    final bool showNavBar = mainProviderData.isUserLoggedIn;
    final UserModel? user = mainProviderData.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child:
            mainProviderData.isLoading
                ? const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryColor,
                  ),
                )
                : Stack(
                  children: [
                    _buildBody(mainProviderData, user),
                    if (showNavBar)
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: _buildNavBar(user),
                      ),
                  ],
                ),
      ),
    );
  }

  Widget _buildBody(MainProviderState mainProviderData, UserModel? user) {
    if (!mainProviderData.isUserLoggedIn || user == null) {
      return const AuthPage();
    } else {
      // Return the appropriate page based on user role and selected index
      return _getPageForUserRole(
        user.role,
        mainProviderData.selectedMainPageIndex,
        user,
      );
    }
  }

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
            topRight: Radius.circular(40),
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
            _buildNavItem(Icons.receipt_long, 0, mainProviderData, 'Orders'),
            _buildNavItem(Icons.home, 1, mainProviderData, 'Home'),
            _buildNavItem(Icons.person, 2, mainProviderData, 'Profile'),
          ],
        ),
      ),
    );
  }

  // Navigation bar for employees
  Widget _buildEmployeeNavBar() {
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
            topRight: Radius.circular(40),
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
              'Appointments',
            ),
            // _buildNavItem(Icons.car_repair, 1, mainProviderData, 'My Services'),
            _buildNavItem(Icons.person, 2, mainProviderData, 'Profile'),
          ],
        ),
      ),
    );
  }

  // Navigation bar for admins
  Widget _buildAdminNavBar() {
    final mainProviderData = ref.watch(mainProvider);

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Container(
        width: double.infinity,
        height: 80,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(40),
            bottomLeft: Radius.circular(40),
            bottomRight: Radius.circular(40),
            topRight: Radius.circular(40),
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
            _buildNavItem(Icons.car_repair, 0, mainProviderData, 'Services'),
            _buildNavItem(Icons.people, 1, mainProviderData, 'Employees'),
            _buildNavItem(Icons.analytics, 2, mainProviderData, 'Analytics'),
            _buildNavItem(Icons.person, 3, mainProviderData, 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    int index,
    MainProviderState mainProviderData,
    String label,
  ) {
    final isSelected = mainProviderData.selectedMainPageIndex == index;

    return GestureDetector(
      onTap: () => ref.read(mainProvider.notifier).setSelectedPage(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected ? Colors.white : Colors.grey, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // Return the appropriate page based on user role and index
  Widget _getPageForUserRole(UserRole role, int index, UserModel user) {
    switch (role) {
      case UserRole.customer:
        switch (index) {
          case 0:
            return const CustomerOrdersScreen();
          case 1:
            return const CustomerHomeScreen();
          case 2:
            return const ProfileScreen();
          default:
            return const CustomerHomeScreen();
        }

      case UserRole.employee:
        switch (index) {
          case 0:
            return const EmployeeServiceRequestsScreen();
          case 1:
            return const Center(child: Text('My Services Coming Soon'));
          case 2:
            return const ProfileScreen();
          default:
            return const EmployeeServiceRequestsScreen();
        }

      case UserRole.admin:
        switch (index) {
          case 0:
            return const ServicesManagementScreen();
          case 1:
            return const EmployeesManagementScreen();
          case 2:
            return const Center(child: Text('Analytics Coming Soon'));
          case 3:
            return const ProfileScreen();
          default:
            return const Center(child: Text('Users Management Coming Soon'));
        }
    }
  }
}
