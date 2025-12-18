import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

class ContactusService {
  // Replace with your actual Indian support number (international format, no +)
  static const String _phoneNumber = "917676498124"; // Example: 91 followed by 10-digit number

  // Optional: Default message
  //static const String _defaultMessage = "Hello, I need help with the app.";

  /// Opens WhatsApp chat with the support number
  /// Optionally pass a custom message
  static Future<void> openWhatsApp({
    required BuildContext context,
  }) async {
    //final String text = Uri.encodeComponent(message ?? _defaultMessage);
    //final Uri whatsappUri = Uri.parse("https://wa.me/$_phoneNumber?text=$text");
    final Uri whatsappUri = Uri.parse("https://wa.me/$_phoneNumber");

    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(
          whatsappUri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        _showSnackBar(context, "WhatsApp is not installed on this device");
      }
    } catch (e) {
      _showSnackBar(context, "Could not open WhatsApp");
    }
  }

  // Helper to show error messages
  static void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}