// ========================================
// Service de configuration utilisateur (manac.config)
// Gère les paramètres locaux pour la connexion hors ligne
// ========================================

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

class ManacConfigService {
  static final ManacConfigService _instance = ManacConfigService._internal();
  factory ManacConfigService() => _instance;
  ManacConfigService._internal();

  static const String _configKey = 'manac_user_config';
  static const String _configPinKey = 'manac_user_pin';
  static const String _isLoggedInKey = 'manac_is_logged_in';
  
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ==================== User Configuration ====================

  /// Save user configuration
  Future<bool> saveUserConfig({
    required String name,
    required String email,
    String? phone,
    String? department,
  }) async {
    final config = {
      'name': name,
      'email': email,
      'phone': phone ?? '',
      'department': department ?? '',
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
    
    return await _prefs?.setString(_configKey, json.encode(config)) ?? false;
  }

  /// Get user configuration
  UserConfig? getUserConfig() {
    final configString = _prefs?.getString(_configKey);
    if (configString == null) return null;
    
    try {
      final map = json.decode(configString) as Map<String, dynamic>;
      return UserConfig.fromMap(map);
    } catch (e) {
      return null;
    }
  }

  /// Update user configuration
  Future<bool> updateUserConfig({
    String? name,
    String? email,
    String? phone,
    String? department,
  }) async {
    final currentConfig = getUserConfig();
    if (currentConfig == null) return false;

    final updatedConfig = {
      'name': name ?? currentConfig.name,
      'email': email ?? currentConfig.email,
      'phone': phone ?? currentConfig.phone,
      'department': department ?? currentConfig.department,
      'createdAt': currentConfig.createdAt,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    return await _prefs?.setString(_configKey, json.encode(updatedConfig)) ?? false;
  }

  /// Delete user configuration
  Future<bool> deleteUserConfig() async {
    return await _prefs?.remove(_configKey) ?? false;
  }

  // ==================== PIN Code Management ====================

  /// Set PIN code for offline authentication
  /// PIN is hashed before storing for security
  Future<bool> setPinCode(String pin) async {
    final hashedPin = _hashPin(pin);
    return await _prefs?.setString(_configPinKey, hashedPin) ?? false;
  }

  /// Verify PIN code
  bool verifyPinCode(String pin) {
    final storedHash = _prefs?.getString(_configPinKey);
    if (storedHash == null) return false;
    
    final inputHash = _hashPin(pin);
    return storedHash == inputHash;
  }

  /// Check if PIN is set
  bool hasPinCode() {
    return _prefs?.containsKey(_configPinKey) ?? false;
  }

  /// Change PIN code
  Future<bool> changePinCode(String oldPin, String newPin) async {
    if (!verifyPinCode(oldPin)) return false;
    return await setPinCode(newPin);
  }

  /// Reset PIN code (admin function)
  Future<bool> resetPinCode() async {
    return await _prefs?.remove(_configPinKey) ?? false;
  }

  /// Check if user is logged in (persisted)
  bool isLoggedIn() {
    return _prefs?.getBool(_isLoggedInKey) ?? false;
  }

  /// Set logged in status
  Future<bool> setLoggedIn(bool value) async {
    return await _prefs?.setBool(_isLoggedInKey, value) ?? false;
  }

  /// Hash PIN using SHA-256
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // ==================== App Settings ====================

  /// Get offline mode status
  bool isOfflineMode() {
    return _prefs?.getBool('offline_mode') ?? false;
  }

  /// Set offline mode status
  Future<bool> setOfflineMode(bool enabled) async {
    return await _prefs?.setBool('offline_mode', enabled) ?? false;
  }

  /// Get last sync timestamp
  String? getLastSyncTime() {
    return _prefs?.getString('last_sync_time');
  }

  /// Set last sync timestamp
  Future<bool> setLastSyncTime(String time) async {
    return await _prefs?.setString('last_sync_time', time) ?? false;
  }

  /// Get auto-sync preference
  bool isAutoSyncEnabled() {
    return _prefs?.getBool('auto_sync') ?? true;
  }

  /// Set auto-sync preference
  Future<bool> setAutoSyncEnabled(bool enabled) async {
    return await _prefs?.setBool('auto_sync', enabled) ?? false;
  }

  /// Get theme preference
  bool isDarkMode() {
    return _prefs?.getBool('dark_mode') ?? false;
  }

  /// Set theme preference
  Future<bool> setDarkMode(bool enabled) async {
    return await _prefs?.setBool('dark_mode', enabled) ?? false;
  }

  // ==================== Clear All ====================

  /// Clear all configuration
  Future<bool> clearAll() async {
    final results = await Future.wait([
      _prefs?.remove(_configKey) ?? Future.value(false),
      _prefs?.remove(_configPinKey) ?? Future.value(false),
      _prefs?.remove('offline_mode') ?? Future.value(false),
      _prefs?.remove('last_sync_time') ?? Future.value(false),
      _prefs?.remove('auto_sync') ?? Future.value(false),
      _prefs?.remove('dark_mode') ?? Future.value(false),
    ]);
    return results.every((r) => r == true);
  }

  // ==================== Export/Import ====================

  /// Export configuration as JSON string
  String exportConfig() {
    final config = {
      'user': getUserConfig()?.toMap() ?? {},
      'hasPin': hasPinCode(),
      'settings': {
        'offlineMode': isOfflineMode(),
        'autoSync': isAutoSyncEnabled(),
        'darkMode': isDarkMode(),
        'lastSyncTime': getLastSyncTime(),
      },
    };
    return json.encode(config);
  }

  /// Import configuration from JSON string
  Future<bool> importConfig(String jsonString) async {
    try {
      final map = json.decode(jsonString) as Map<String, dynamic>;
      
      // Import user config
      if (map['user'] != null) {
        final user = map['user'] as Map<String, dynamic>;
        await saveUserConfig(
          name: user['name'] ?? '',
          email: user['email'] ?? '',
          phone: user['phone'],
          department: user['department'],
        );
      }

      // Import settings
      if (map['settings'] != null) {
        final settings = map['settings'] as Map<String, dynamic>;
        await setOfflineMode(settings['offlineMode'] ?? false);
        await setAutoSyncEnabled(settings['autoSync'] ?? true);
        await setDarkMode(settings['darkMode'] ?? false);
        if (settings['lastSyncTime'] != null) {
          await setLastSyncTime(settings['lastSyncTime']);
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}

/// User configuration model
class UserConfig {
  final String name;
  final String email;
  final String phone;
  final String department;
  final String createdAt;
  final String updatedAt;

  UserConfig({
    required this.name,
    required this.email,
    this.phone = '',
    this.department = '',
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserConfig.fromMap(Map<String, dynamic> map) {
    return UserConfig(
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      department: map['department'] ?? '',
      createdAt: map['createdAt'] ?? DateTime.now().toIso8601String(),
      updatedAt: map['updatedAt'] ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'department': department,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
