import 'package:flutter/material.dart';

class SubscriptionWarningDialog extends StatelessWidget {
  final int daysLeft;
  final VoidCallback onDismiss;

  const SubscriptionWarningDialog({
    super.key,
    required this.daysLeft,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange),
          const SizedBox(width: 8),
          const Text('Subscription Expiring Soon'),
        ],
      ),
      content: Text(
        'Your subscription will expire in $daysLeft day${daysLeft > 1 ? 's' : ''}. '
        'Please renew to continue using the app without interruption.\n\n'
        'Contact support for renewal.',
      ),
      actions: [
        TextButton(
          onPressed: () {
            onDismiss();
            Navigator.pop(context);
          },
          child: const Text('Remind Me Later'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            // In real app: open WhatsApp/call/email
          },
          child: const Text('Contact Support'),
        ),
      ],
    );
  }
}
