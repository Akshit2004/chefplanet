import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:chef_plannet/providers/auth_provider.dart';
import '../widgets/app_toast.dart';
import 'package:go_router/go_router.dart';
import 'package:chef_plannet/widgets/animated_silhouette.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(icon: const Icon(LucideIcons.settings), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Profile Header
            GestureDetector(
              onTap: () => _pickImage(context),
              child: Stack(
                children: [
                  auth.profileImageUrl != null
                      ? CircleAvatar(
                          radius: 50,
                          backgroundImage: MemoryImage(
                            base64Decode(auth.profileImageUrl!),
                          ),
                        )
                      : const AnimatedSilhouette(radius: 50),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: theme.primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        LucideIcons.camera,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              auth.userName ?? 'User Name',
              style: theme.textTheme.displayLarge?.copyWith(fontSize: 24),
            ),
            const SizedBox(height: 4),
            Text(
              auth.userEmail ?? 'user@example.com',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),

            // Profile Options
            _buildProfileOption(
              context,
              icon: LucideIcons.shoppingBag,
              title: 'My Orders',
              subtitle: auth.orders.isEmpty
                  ? 'No active orders'
                  : '${auth.orders.length} orders',
              onTap: () => context.push('/orders'),
            ),
            _buildProfileOption(
              context,
              icon: LucideIcons.mapPin,
              title: 'Shipping Addresses',
              subtitle: auth.addresses.isEmpty
                  ? 'Add your address'
                  : '${auth.addresses.length} saved',
              onTap: () => context.push('/addresses'),
            ),
            _buildProfileOption(
              context,
              icon: LucideIcons.creditCard,
              title: 'Payment Methods',
              subtitle: 'Manage your payments',
              onTap: () => context.push('/payment'),
            ),
            _buildProfileOption(
              context,
              icon: LucideIcons.bell,
              title: 'Notifications',
              subtitle: 'App & Email',
              onTap: () => context.push('/notifications'),
            ),
            _buildProfileOption(
              context,
              icon: LucideIcons.shield,
              title: 'Security',
              subtitle: 'Account protection',
              onTap: () => context.push('/security'),
            ),
            const SizedBox(height: 32),

            // Logout Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    await Provider.of<AuthProvider>(
                      context,
                      listen: false,
                    ).logout();
                    if (context.mounted) context.go('/login');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Log Out',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(BuildContext context) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 75,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      final base64String = base64Encode(bytes);
      if (context.mounted) {
        final success = await Provider.of<AuthProvider>(
          context,
          listen: false,
        ).updateProfileImage(base64String);
        if (!success && context.mounted) {
          AppToast.show(
            context,
            'Failed to update profile image',
            success: false,
          );
        }
      }
    }
  }

  Widget _buildProfileOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.primaryColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: theme.primaryColor),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(subtitle, style: theme.textTheme.bodyMedium),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}
