import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/sync_provider.dart';
import '../services/local_storage_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _autoSync = true;
  bool _notifications = true;
  String _syncInterval = '15';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    _autoSync = LocalStorageService.getSetting('autoSync', defaultValue: true) as bool;
    _notifications = LocalStorageService.getSetting('notifications', defaultValue: true) as bool;
    _syncInterval = LocalStorageService.getSetting('syncInterval', defaultValue: '15') as String;
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

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Sign In'),
            subtitle: authProvider.isAuthenticated
                ? Text(authProvider.userName ?? 'Signed in')
                : const Text('Sign in to sync data across devices'),
            trailing: authProvider.isAuthenticated
                ? TextButton(
                    onPressed: () => _showSignOutDialog(context),
                    child: const Text('Sign Out'),
                  )
                : TextButton(
                    onPressed: () => _showSignInDialog(context),
                    child: const Text('Sign In'),
                  ),
          ),
          if (authProvider.isAuthenticated && authProvider.error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                authProvider.error,
                style: const TextStyle(color: Colors.red),
              ),
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
          SwitchListTile(
            title: const Text('Notifications'),
            subtitle: const Text('Receive low stock alerts'),
            value: _notifications,
            onChanged: (value) {
              setState(() {
                _notifications = value;
              });
              LocalStorageService.setSetting('notifications', value);
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Language'),
            subtitle: const Text('English'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Implement language selection
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Theme'),
            subtitle: const Text('System default'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Implement theme selection
            },
          ),
        ],
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
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Open privacy policy
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Open terms of service
            },
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
