import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flying_auto_services/utils/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

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
              // Handle
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
                    // Profile header
                    _buildProfileHeader(context),
                    const SizedBox(height: 20),
                    
                    // Contact information
                    _buildSectionTitle('Contact Information'),
                    _buildContactItem(
                      context,
                      icon: Icons.phone,
                      title: 'Phone',
                      value: phoneNumber,
                      onTap: () => _makePhoneCall(phoneNumber),
                      onLongPress: () => _copyToClipboard(context, phoneNumber),
                    ),
                    _buildContactItem(
                      context,
                      icon: Icons.email,
                      title: 'Email',
                      value: email,
                      onTap: () => _sendEmail(email),
                      onLongPress: () => _copyToClipboard(context, email),
                    ),
                    if (location != null)
                      _buildContactItem(
                        context,
                        icon: Icons.location_on,
                        title: 'Location',
                        value: location!,
                        onTap: () => _openMap(location!),
                        onLongPress: () => _copyToClipboard(context, location!),
                      ),
                    if (website != null)
                      _buildContactItem(
                        context,
                        icon: Icons.language,
                        title: 'Website',
                        value: website!,
                        onTap: () => _openUrl(website!),
                        onLongPress: () => _copyToClipboard(context, website!),
                      ),
                    
                    // Social media links
                    if (socialMediaLinks != null && socialMediaLinks!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildSectionTitle('Social Media'),
                      ...socialMediaLinks!.entries.map((entry) {
                        IconData icon;
                        switch (entry.key.toLowerCase()) {
                          case 'instagram':
                            icon = Icons.camera_alt;
                            break;
                          case 'twitter':
                            icon = Icons.chat;
                            break;
                          case 'youtube':
                            icon = Icons.play_circle_fill;
                            break;
                          case 'tiktok':
                            icon = Icons.music_note;
                            break;
                          default:
                            icon = Icons.link;
                        }
                        
                        return _buildContactItem(
                          context,
                          icon: icon,
                          title: entry.key,
                          value: entry.value,
                          onTap: () => _openUrl(entry.value),
                          onLongPress: () => _copyToClipboard(context, entry.value),
                        );
                      }).toList(),
                    ],
                    
                    // Services
                    if (services != null && services!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildSectionTitle('Services'),
                      ...services!.map((service) {
                        return _buildServiceItem(
                          name: service['name'],
                          price: service['price'],
                          description: service['description'],
                        );
                      }).toList(),
                    ],
                    
                    // Notes
                    if (notes != null && notes!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildSectionTitle('Notes'),
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(notes!),
                      ),
                    ],
                    
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Column(
      children: [
        // Profile image
        CircleAvatar(
          radius: 50,
          backgroundColor: AppColor.primary.withOpacity(0.1),
          backgroundImage: profileImageUrl != null ? NetworkImage(profileImageUrl!) : null,
          child: profileImageUrl == null
              ? Icon(
                  Icons.person,
                  size: 50,
                  color: AppColor.primary,
                )
              : null,
        ),
        const SizedBox(height: 15),
        
        // Name
        Text(
          name,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 5),
        
        // Role
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          decoration: BoxDecoration(
            color: AppColor.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            role,
            style: TextStyle(
              color: AppColor.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColor.primary,
        ),
      ),
    );
  }

  Widget _buildContactItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
  }) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColor.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: AppColor.primary,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColor.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                _getActionIcon(title),
                color: AppColor.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  IconData _getActionIcon(String title) {
    switch (title.toLowerCase()) {
      case 'phone':
        return Icons.call;
      case 'email':
        return Icons.email;
      case 'location':
        return Icons.map;
      case 'website':
      case 'instagram':
      case 'twitter':
      case 'youtube':
      case 'tiktok':
        return Icons.open_in_new;
      default:
        return Icons.arrow_forward_ios;
    }
  }

  Widget _buildServiceItem({
    required String name,
    required double price,
    String? description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                '\$${price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColor.primary,
                ),
              ),
            ],
          ),
          if (description != null) ...[
            const SizedBox(height: 5),
            Text(
              description,
              style: const TextStyle(
                color: AppColor.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendEmail(String email) async {
    final Uri uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openMap(String address) async {
    final Uri uri = Uri.parse('https://maps.google.com/?q=$address');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openUrl(String url) async {
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
