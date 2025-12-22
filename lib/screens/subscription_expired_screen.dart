import 'package:exp_edge/services/contactus_service.dart';
import 'package:flutter/material.dart';
import '../models/organization.dart';

class SubscriptionExpiredScreen extends StatelessWidget {
  final Organization organization;

  const SubscriptionExpiredScreen({
    super.key,
    required this.organization,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_clock,
                size: 80,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 24),
              const Text(
                'Subscription Expired',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Your ${organization.subscriptionStatus == 'trial' ? 'trial' : 'subscription'} has expired. '
                'Please renew to continue using Exp Edge.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildInfoRow('Organization', organization.name),
                      const Divider(height: 24),
                      _buildInfoRow('Email', organization.email),
                      const Divider(height: 24),
                      _buildInfoRow('Plan', organization.subscriptionPlan.toUpperCase()),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  ContactusService.openWhatsApp(context: context);
                },
                icon: const Icon(Icons.phone),
                label: const Text('Contact for Renewal'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // TextButton(
              //   onPressed: () async {
              //     await AuthService().signOut();
              //     if (context.mounted) {
              //       Navigator.pushAndRemoveUntil(
              //         context,
              //         MaterialPageRoute(builder: (_) => const LoginScreen()),
              //         (route) => false,
              //       );
              //     }
              //   },
              //   child: const Text('Logout'),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}