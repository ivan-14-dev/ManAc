import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/sync_provider.dart';
import '../services/local_storage_service.dart';
import '../services/manac_config_service.dart';
import '../services/app_language_service.dart';
import '../services/app_theme_service.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _autoSync = true;
  bool _notifications = true;
  String _syncInterval = '15';
  final ManacConfigService _configService = ManacConfigService();
  final AppLanguageService _languageService = AppLanguageService();
  final AppThemeService _themeService = AppThemeService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    _autoSync = LocalStorageService.getSetting('autoSync', defaultValue: true) as bool;
    _notifications = LocalStorageService.getSetting('notifications', defaultValue: true) as bool;
    _syncInterval = LocalStorageService.getSetting('syncInterval', defaultValue: '15') as String;
    _configService.init();
    _languageService.init();
    _themeService.init();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Account section
          _buildSectionHeader('Account'),
          _buildAccountCard(context),
          const SizedBox(height: 24),
          // Sync settings
          _buildSectionHeader('Sync Settings'),
          _buildSyncSettingsCard(),
          const SizedBox(height: 24),
          // App settings
          _buildSectionHeader('App Settings'),
          _buildAppSettingsCard(),
          const SizedBox(height: 24),
          // Data management
          _buildSectionHeader('Data Management'),
          _buildDataManagementCard(),
          const SizedBox(height: 24),
          // About
          _buildSectionHeader('About'),
          _buildAboutCard(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userConfig = _configService.getUserConfig();

    return Card(
      child: Column(
        children: [
          // Profile section
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: userConfig?.name != null && userConfig!.name.isNotEmpty
                  ? Text(userConfig.name[0].toUpperCase())
                  : const Icon(Icons.person, color: Colors.white),
            ),
            title: Text(userConfig?.name ?? 'Guest'),
            subtitle: Text(userConfig?.email ?? 'No email'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showProfileDialog(context),
          ),
          const Divider(),
          // User info fields
          if (userConfig != null) ...[
            ListTile(
              leading: const Icon(Icons.badge),
              title: const Text('Name'),
              subtitle: Text(userConfig.name.isNotEmpty ? userConfig.name : 'Not set'),
              trailing: const Icon(Icons.edit, size: 18),
              onTap: () => _showEditFieldDialog(context, 'name', userConfig.name),
            ),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Email'),
              subtitle: Text(userConfig.email.isNotEmpty ? userConfig.email : 'Not set'),
              trailing: const Icon(Icons.edit, size: 18),
              onTap: () => _showEditFieldDialog(context, 'email', userConfig.email),
            ),
            ListTile(
              leading: const Icon(Icons.business),
              title: const Text('Department'),
              subtitle: Text(userConfig.department.isNotEmpty ? userConfig.department : 'Not set'),
              trailing: const Icon(Icons.edit, size: 18),
              onTap: () => _showEditFieldDialog(context, 'department', userConfig.department),
            ),
            ListTile(
              leading: const Icon(Icons.phone),
              title: const Text('Phone'),
              subtitle: Text(userConfig.phone.isNotEmpty ? userConfig.phone : 'Not set'),
              trailing: const Icon(Icons.edit, size: 18),
              onTap: () => _showEditFieldDialog(context, 'phone', userConfig.phone),
            ),
            const Divider(),
          ],
          // PIN Management
          ListTile(
            leading: const Icon(Icons.pin),
            title: const Text('PIN Code'),
            subtitle: Text(_configService.hasPinCode() ? 'PIN is set' : 'No PIN set'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showPinManagementDialog(context),
          ),
          // Sign In/Out
          const Divider(),
          ListTile(
            leading: Icon(
              authProvider.isAuthenticated ? Icons.logout : Icons.login,
              color: authProvider.isAuthenticated ? Colors.red : Colors.green,
            ),
            title: Text(authProvider.isAuthenticated ? 'Sign Out' : 'Sign In'),
            subtitle: Text(
              authProvider.isAuthenticated
                  ? 'Sign out from Firebase account'
                  : 'Sign in to sync data across devices',
            ),
            onTap: () {
              if (authProvider.isAuthenticated) {
                _showSignOutDialog(context);
              } else {
                _showSignInDialog(context);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showProfileDialog(BuildContext context) {
    final userConfig = _configService.getUserConfig();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('User Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Theme.of(context).primaryColor,
              child: userConfig?.name != null && userConfig!.name.isNotEmpty
                  ? Text(userConfig.name[0].toUpperCase(), style: const TextStyle(fontSize: 32, color: Colors.white))
                  : const Icon(Icons.person, size: 32, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(userConfig?.name ?? 'Guest', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(userConfig?.email ?? 'No email'),
            Text(userConfig?.department ?? ''),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showEditFieldDialog(BuildContext context, String field, String currentValue) {
    final controller = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${field.substring(0, 1).toUpperCase()}${field.substring(1)}'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: field.substring(0, 1).toUpperCase() + field.substring(1),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              switch (field) {
                case 'name':
                  await _configService.updateUserConfig(name: controller.text);
                  break;
                case 'email':
                  await _configService.updateUserConfig(email: controller.text);
                  break;
                case 'department':
                  await _configService.updateUserConfig(department: controller.text);
                  break;
                case 'phone':
                  await _configService.updateUserConfig(phone: controller.text);
                  break;
              }
              if (mounted) {
                Navigator.pop(context);
                setState(() {});
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showPinManagementDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PIN Code Management'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add),
              title: Text(_configService.hasPinCode() ? 'Change PIN' : 'Set PIN'),
              onTap: () {
                Navigator.pop(context);
                _showSetPinDialog(context);
              },
            ),
            if (_configService.hasPinCode())
              ListTile(
                leading: const Icon(Icons.lock_open, color: Colors.orange),
                title: const Text('Reset PIN'),
                onTap: () {
                  Navigator.pop(context);
                  _showResetPinDialog(context);
                },
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSetPinDialog(BuildContext context) {
    final pinController = TextEditingController();
    final confirmController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_configService.hasPinCode() ? 'Change PIN' : 'Set PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: pinController,
              decoration: const InputDecoration(
                labelText: 'Enter PIN (4-6 digits)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: confirmController,
              decoration: const InputDecoration(
                labelText: 'Confirm PIN',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (pinController.text.length < 4) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN must be at least 4 digits')),
                );
                return;
              }
              if (pinController.text != confirmController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PINs do not match')),
                );
                return;
              }
              await _configService.setPinCode(pinController.text);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN set successfully'), backgroundColor: Colors.green),
                );
                setState(() {});
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showResetPinDialog(BuildContext context) {
    final currentPinController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your current PIN to reset:'),
            const SizedBox(height: 16),
            TextField(
              controller: currentPinController,
              decoration: const InputDecoration(
                labelText: 'Current PIN',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_configService.verifyPinCode(currentPinController.text)) {
                Navigator.pop(context);
                _showSetPinDialog(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Incorrect PIN'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncSettingsCard() {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Auto Sync'),
            subtitle: const Text('Automatically sync when online'),
            value: _autoSync,
            onChanged: (value) {
              setState(() {
                _autoSync = value;
              });
              LocalStorageService.setSetting('autoSync', value);
              if (value) {
                Provider.of<SyncProvider>(context, listen: false).startPeriodicSync();
              } else {
                Provider.of<SyncProvider>(context, listen: false).stopPeriodicSync();
              }
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Sync Interval'),
            subtitle: Text('Every $_syncInterval minutes'),
            trailing: DropdownButton<String>(
              value: _syncInterval,
              items: ['5', '15', '30', '60'].map((interval) {
                return DropdownMenuItem(
                  value: interval,
                  child: Text('$interval min'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _syncInterval = value!;
                });
                LocalStorageService.setSetting('syncInterval', value);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppSettingsCard() {
    return Card(
      child: Column(
        children: [
          // Language
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Langue / Language'),
            subtitle: Text(_languageService.currentLanguageName),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLanguageDialog(context),
          ),
          const Divider(),
          // Theme
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Thème'),
            subtitle: Text(_themeService.themeModeName == 'light' ? 'Mode clair' : 
                         _themeService.themeModeName == 'dark' ? 'Mode sombre' : 'Système'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemeDialog(context),
          ),
          const Divider(),
          // Secondary Color
          ListTile(
            leading: const Icon(Icons.color_lens),
            title: const Text('Couleur secondaire'),
            trailing: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _themeService.secondaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey),
              ),
            ),
            onTap: () => _showColorPickerDialog(context),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Notifications'),
            subtitle: const Text('Recevoir les alertes de stock'),
            value: _notifications,
            onChanged: (value) {
              setState(() {
                _notifications = value;
              });
              LocalStorageService.setSetting('notifications', value);
            },
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisir la langue'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppLanguageService.supportedLanguages.entries.map((entry) {
            return ListTile(
              leading: Radio<String>(
                value: entry.key,
                groupValue: _languageService.locale.languageCode,
                onChanged: (value) async {
                  await _languageService.setLanguage(value!);
                  if (mounted) Navigator.pop(context);
                  setState(() {});
                },
              ),
              title: Text(entry.value),
              onTap: () async {
                await _languageService.setLanguage(entry.key);
                if (mounted) Navigator.pop(context);
                setState(() {});
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisir le thème'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.brightness_auto),
              title: const Text('Système'),
              onTap: () async {
                await _themeService.setThemeMode(ThemeMode.system);
                if (mounted) Navigator.pop(context);
                setState(() {});
              },
            ),
            ListTile(
              leading: const Icon(Icons.light_mode),
              title: const Text('Mode clair'),
              onTap: () async {
                await _themeService.setThemeMode(ThemeMode.light);
                if (mounted) Navigator.pop(context);
                setState(() {});
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text('Mode sombre'),
              onTap: () async {
                await _themeService.setThemeMode(ThemeMode.dark);
                if (mounted) Navigator.pop(context);
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showColorPickerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Couleur secondaire'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AppThemeService.availableColors.map((color) {
            return GestureDetector(
              onTap: () async {
                await _themeService.setSecondaryColor(color);
                if (mounted) Navigator.pop(context);
                setState(() {});
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: _themeService.secondaryColor == color
                      ? Border.all(color: Colors.black, width: 3)
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDataManagementCard() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.cloud_download),
            title: const Text('Export Data'),
            subtitle: const Text('Export stock data to file'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _exportData,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.cloud_upload),
            title: const Text('Import Data'),
            subtitle: const Text('Import stock data from file'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _importData,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Clear All Data', style: TextStyle(color: Colors.red)),
            subtitle: const Text('Delete all local data'),
            onTap: _showClearDataDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Version'),
            subtitle: const Text('1.0.0'),
            onTap: () => _showVersionDialog(context),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('Développeur'),
            subtitle: const Text('BAYIGA BOGMIS Ivan / Technical Team'),
            onTap: () => _showDeveloperDialog(context),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Politique de confidentialité'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Conditions d\'utilisation'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showVersionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Version Info'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Manac - Stock Management App'),
            SizedBox(height: 8),
            Text('Version: 1.0.0'),
            Text('Build: 2026.02.16'),
            SizedBox(height: 8),
            Text('© 2024 Manac. Tous droits réservés.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showDeveloperDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Équipe de développement'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, size: 40),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('BAYIGA BOGMIS Ivan', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Technical Team'),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),
            Text('Développé avec Flutter et Firebase'),
            SizedBox(height: 8),
            Text('Pour toute question technique, contacter l\'administrateur.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSignInDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const SignInDialog(),
    );
  }

  void _showSignOutDialog(BuildContext context) {
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
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).signOut();
              Navigator.pop(context);
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will delete all local data including stock items, activities, and sync queue. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              LocalStorageService.clearAllData();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All data cleared')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _exportData() {
    // TODO: Implement data export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export feature coming soon')),
    );
  }

  void _importData() {
    // TODO: Implement data import
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Import feature coming soon')),
    );
  }
}

class SignInDialog extends StatefulWidget {
  const SignInDialog({super.key});

  @override
  State<SignInDialog> createState() => _SignInDialogState();
}

class _SignInDialogState extends State<SignInDialog> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isSignUp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return AlertDialog(
      title: Text(_isSignUp ? 'Create Account' : 'Sign In'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isSignUp)
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
            if (_isSignUp) const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            if (authProvider.error.isNotEmpty)
              Text(
                authProvider.error,
                style: const TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              _isSignUp = !_isSignUp;
            });
          },
          child: Text(_isSignUp ? 'Already have an account?' : 'Create an account'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: authProvider.isLoading
              ? null
              : () {
                  if (_isSignUp) {
                    authProvider.signUp(
                      email: _emailController.text,
                      password: _passwordController.text,
                      name: _nameController.text,
                    );
                  } else {
                    authProvider.signIn(
                      email: _emailController.text,
                      password: _passwordController.text,
                    );
                  }
                  if (authProvider.isAuthenticated) {
                    Navigator.pop(context);
                  }
                },
          child: authProvider.isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isSignUp ? 'Sign Up' : 'Sign In'),
        ),
      ],
    );
  }
}
