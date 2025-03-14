import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flying_auto_services/models/user_model.dart';
import 'package:flying_auto_services/providers/main_provider.dart';
import 'package:flying_auto_services/utils/app_colors.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mainProviderData = ref.watch(mainProvider);
    final UserModel? user = mainProviderData.currentUser;

    if (user == null) {
      return const Center(child: Text('User not found'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColor.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile header
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColor.primary,
                    child: user.profileImageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: Image.network(
                              user.profileImageUrl!,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.white,
                          ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _getRoleText(user.role),
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColor.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Profile menu
            _buildMenuItem(
              icon: Icons.person,
              title: 'Personal Profile',
              onTap: () {
                // Navigate to personal profile edit screen
              },
            ),
            _buildDivider(),
            _buildMenuItem(
              icon: Icons.help,
              title: 'Contact Us',
              onTap: () {
                // Navigate to contact us screen
              },
            ),
            _buildDivider(),
            _buildMenuItem(
              icon: Icons.info,
              title: 'About App',
              onTap: () {
                // Navigate to about app screen
              },
            ),
            _buildDivider(),
            _buildMenuItem(
              icon: Icons.gavel,
              title: 'Terms & Conditions',
              onTap: () {
                // Navigate to terms screen
              },
            ),
            _buildDivider(),
            _buildMenuItem(
              icon: Icons.privacy_tip,
              title: 'Privacy Policy',
              onTap: () {
                // Navigate to privacy policy screen
              },
            ),
            _buildDivider(),
            _buildNotificationToggle(context),
            _buildDivider(),
            _buildMenuItem(
              icon: Icons.logout,
              title: 'Sign Out',
              onTap: () {
                _showSignOutDialog(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: AppColor.primary,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColor.textSecondary,
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return const Divider(
      color: AppColor.divider,
      height: 1,
    );
  }

  Widget _buildNotificationToggle(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) {
        return SwitchListTile(
          title: const Text(
            'Notifications',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          value: true, // Replace with actual notification state
          activeColor: AppColor.primary,
          secondary: const Icon(
            Icons.notifications,
            color: AppColor.primary,
          ),
          onChanged: (value) {
            // Toggle notification state
            setState(() {
              // Update notification state
            });
          },
        );
      },
    );
  }

  void _showSignOutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(mainProvider.notifier).signOut();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  String _getRoleText(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.employee:
        return 'Employee';
      case UserRole.customer:
        return 'Customer';
      default:
        return 'User';
    }
  }
}
