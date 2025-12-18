import 'package:exp_edge/services/contactus_service.dart';
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
      titleTextStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange),
          const SizedBox(width: 8),
          const Text('Subscription Expiring Soon',),
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
            ContactusService.openWhatsApp(context: context);
          },
          child: const Text('Contact Support'),
        ),
      ],
    );
  }
}
