// lib/services/biometric_service.dart

import 'dart:io'; // Add this import
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();
  static const _storage = FlutterSecureStorage();
  
  // Keys for secure storage
  static const _keyEmail = 'user_email';
  static const _keyPassword = 'user_password';
  static const _keyBiometricEnabled = 'biometric_enabled';

  // Check if platform supports biometrics (mobile only)
  static bool _isMobilePlatform() {
    return Platform.isAndroid || Platform.isIOS;
  }

  // Check if device supports biometrics
  static Future<bool> canUseBiometrics() async {
    // Disable biometrics on desktop
    if (!_isMobilePlatform()) return false;
    
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      return canCheck && isDeviceSupported;
    } catch (e) {
      return false;
    }
  }

  // Get available biometric types
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    if (!_isMobilePlatform()) return [];
    
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  // Authenticate with biometrics
  static Future<bool> authenticate() async {
    if (!_isMobilePlatform()) return false;
    
    try {
      return await _auth.authenticate(
        localizedReason: 'Authenticate to access Exp Edge',
        biometricOnly: true
      );
    } catch (e) {
      print('Biometric authentication error: $e');
      return false;
    }
  }

  // Save credentials securely
  static Future<void> saveCredentials(String email, String password) async {
    if (!_isMobilePlatform()) return; // Skip on desktop
    
    try {
      await _storage.write(key: _keyEmail, value: email);
      await _storage.write(key: _keyPassword, value: password);
    } catch (e) {
      print('Error saving credentials: $e');
    }
  }

  // Get saved credentials
  static Future<Map<String, String?>> getCredentials() async {
    if (!_isMobilePlatform()) {
      return {'email': null, 'password': null};
    }
    
    try {
      final email = await _storage.read(key: _keyEmail);
      final password = await _storage.read(key: _keyPassword);
      return {'email': email, 'password': password};
    } catch (e) {
      print('Error reading credentials: $e');
      return {'email': null, 'password': null};
    }
  }

  // Clear saved credentials
  static Future<void> clearCredentials() async {
    if (!_isMobilePlatform()) return; // Skip on desktop - THIS FIXES YOUR ERROR!
    
    try {
      await _storage.delete(key: _keyEmail);
      await _storage.delete(key: _keyPassword);
      await _storage.delete(key: _keyBiometricEnabled);
    } catch (e) {
      print('Error clearing credentials: $e');
    }
  }

  // Enable/disable biometric
  static Future<void> setBiometricEnabled(bool enabled) async {
    if (!_isMobilePlatform()) return; // Skip on desktop
    
    try {
      await _storage.write(key: _keyBiometricEnabled, value: enabled.toString());
    } catch (e) {
      print('Error setting biometric enabled: $e');
    }
  }

  // Check if biometric is enabled
  static Future<bool> isBiometricEnabled() async {
    if (!_isMobilePlatform()) return false; // Always false on desktop
    
    try {
      final value = await _storage.read(key: _keyBiometricEnabled);
      return value == 'true';
    } catch (e) {
      print('Error reading biometric enabled: $e');
      return false;
    }
  }
}