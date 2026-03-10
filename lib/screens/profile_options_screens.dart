import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Methods')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.creditCard, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('No payment methods saved'),
          ],
        ),
      ),
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        children: const [
          ListTile(
            title: Text('App Notifications'),
            trailing: Switch(value: true, onChanged: null),
          ),
          ListTile(
            title: Text('Email Notifications'),
            trailing: Switch(value: false, onChanged: null),
          ),
        ],
      ),
    );
  }
}

class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Security')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(LucideIcons.lock),
            title: const Text('Change Password'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(LucideIcons.shieldCheck),
            title: const Text('Two-Factor Authentication'),
            trailing: Switch(value: false, onChanged: null),
          ),
        ],
      ),
    );
  }
}
