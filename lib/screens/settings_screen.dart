import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../providers/auth_provider.dart';
import '../providers/sync_provider.dart';
import '../services/local_storage_service.dart';
import '../services/manac_config_service.dart';
import '../services/app_language_service.dart';
import '../services/app_theme_service.dart';
import '../services/firebase_service.dart';
import '../services/local_api_service.dart';
import '../theme/app_theme.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';
import 'sync_status_screen.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Column(
        children: [
          // Gradient Header
          _buildGradientHeader(context),
          
          // Content
          Expanded(
            child: Container(
              color: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Account section
                    _buildSectionHeader('Account', Icons.person_outline),
                    _buildAccountCard(context),
                    const SizedBox(height: 24),
                    // Sync settings
                    _buildSectionHeader('Synchronisation', Icons.sync),
                    _buildSyncSettingsCard(context),
                    const SizedBox(height: 24),
                    // App settings
                    _buildSectionHeader('Paramètres de l\'app', Icons.settings),
                    _buildAppSettingsCard(context),
                    const SizedBox(height: 24),
                    // Data management
                    _buildSectionHeader('Gestion des données', Icons.storage),
                    _buildDataManagementCard(context),
                    const SizedBox(height: 24),
                    // About
                    _buildSectionHeader('À propos', Icons.info_outline),
                    _buildAboutCard(context),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.orangeBlueGradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              // Back button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Paramètres',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      'Configurez l\'application',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Sync status indicator
              Consumer<SyncProvider>(
                builder: (context, syncProvider, child) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SyncStatusScreen()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (syncProvider.isSyncing)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          else
                            const Icon(
                              Icons.sync,
                              color: Colors.white,
                              size: 18,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 18,
              color: AppTheme.primaryOrange,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey[800],
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userConfig = _configService.getUserConfig();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppTheme.orangeBlueGradient,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: userConfig?.name != null && userConfig!.name.isNotEmpty
                      ? Text(
                          userConfig.name[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryOrange,
                          ),
                        )
                      : const Icon(Icons.person, size: 30, color: AppTheme.primaryOrange),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userConfig?.name ?? 'Invité',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        userConfig?.email ?? 'Aucun email',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: () => _showProfileDialog(context),
                ),
              ],
            ),
          ),
          // User info fields
          if (userConfig != null) ...[
            _buildSettingsTile(
              icon: Icons.badge,
              title: 'Nom',
              subtitle: userConfig.name.isNotEmpty ? userConfig.name : 'Non défini',
              onTap: () => _showEditFieldDialog(context, 'name', userConfig.name),
            ),
            _buildSettingsTile(
              icon: Icons.email,
              title: 'Email',
              subtitle: userConfig.email.isNotEmpty ? userConfig.email : 'Non défini',
              onTap: () => _showEditFieldDialog(context, 'email', userConfig.email),
            ),
            _buildSettingsTile(
              icon: Icons.business,
              title: 'Département',
              subtitle: userConfig.department.isNotEmpty ? userConfig.department : 'Non défini',
              onTap: () => _showEditFieldDialog(context, 'department', userConfig.department),
            ),
            _buildSettingsTile(
              icon: Icons.phone,
              title: 'Téléphone',
              subtitle: userConfig.phone.isNotEmpty ? userConfig.phone : 'Non défini',
              onTap: () => _showEditFieldDialog(context, 'phone', userConfig.phone),
            ),
          ],
          const Divider(height: 1),
          // PIN Management
          _buildSettingsTile(
            icon: Icons.pin,
            title: 'Code PIN',
            subtitle: _configService.hasPinCode() ? 'PIN configuré' : 'Aucun PIN',
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showPinManagementDialog(context),
          ),
          const Divider(height: 1),
          // Sign In/Out
          _buildSettingsTile(
            icon: authProvider.isAuthenticated ? Icons.logout : Icons.login,
            title: authProvider.isAuthenticated ? 'Déconnexion' : 'Connexion',
            subtitle: authProvider.isAuthenticated
                ? 'Se déconnecter du compte Firebase'
                : 'Se connecter pour synchroniser les données',
            iconColor: authProvider.isAuthenticated ? Colors.red : Colors.green,
            trailing: const Icon(Icons.chevron_right),
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

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
    Color? iconColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (iconColor ?? AppTheme.primaryOrange).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor ?? AppTheme.primaryOrange, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.grey[800],
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isDark ? Colors.white60 : Colors.grey[600],
          fontSize: 13,
        ),
      ),
      trailing: trailing ?? Icon(Icons.chevron_right, color: Colors.grey[400]),
      onTap: onTap,
    );
  }

  void _showProfileDialog(BuildContext context) {
    final userConfig = _configService.getUserConfig();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.person, color: AppTheme.primaryOrange),
            SizedBox(width: 12),
            Text('Profil Utilisateur'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.primaryOrange,
              child: userConfig?.name != null && userConfig!.name.isNotEmpty
                  ? Text(
                      userConfig.name[0].toUpperCase(),
                      style: const TextStyle(fontSize: 40, color: Colors.white),
                    )
                  : const Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              userConfig?.name ?? 'Invité',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              userConfig?.email ?? 'Aucun email',
              style: TextStyle(color: Colors.grey[600]),
            ),
            if (userConfig?.department.isNotEmpty ?? false) ...[
              const SizedBox(height: 4),
              Text(
                userConfig!.department,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Modifier ${field.substring(0, 1).toUpperCase()}${field.substring(1)}'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: field.substring(0, 1).toUpperCase() + field.substring(1),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: Icon(_getFieldIcon(field)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
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
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  IconData _getFieldIcon(String field) {
    switch (field) {
      case 'name':
        return Icons.person;
      case 'email':
        return Icons.email;
      case 'department':
        return Icons.business;
      case 'phone':
        return Icons.phone;
      default:
        return Icons.edit;
    }
  }

  void _showPinManagementDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.pin, color: AppTheme.primaryOrange),
            SizedBox(width: 12),
            Text('Gestion du PIN'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                _configService.hasPinCode() ? Icons.lock : Icons.add,
                color: AppTheme.primaryOrange,
              ),
              title: Text(_configService.hasPinCode() ? 'Changer le PIN' : 'Définir un PIN'),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: AppTheme.primaryOrange.withOpacity(0.1),
              onTap: () {
                Navigator.pop(context);
                _showSetPinDialog(context);
              },
            ),
            if (_configService.hasPinCode()) ...[
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.lock_open, color: Colors.orange),
                title: const Text('Réinitialiser le PIN'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: Colors.orange.withOpacity(0.1),
                onTap: () {
                  Navigator.pop(context);
                  _showResetPinDialog(context);
                },
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(_configService.hasPinCode() ? 'Changer le PIN' : 'Définir un PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: pinController,
              decoration: InputDecoration(
                labelText: 'Entrer le PIN (4-6 chiffres)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.lock),
              ),
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: confirmController,
              decoration: InputDecoration(
                labelText: 'Confirmer le PIN',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.lock_outline),
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
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (pinController.text.length < 4) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Le PIN doit contenir au moins 4 chiffres')),
                );
                return;
              }
              if (pinController.text != confirmController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Les PINs ne correspondent pas')),
                );
                return;
              }
              await _configService.setPinCode(pinController.text);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PIN défini avec succès'),
                    backgroundColor: Colors.green,
                  ),
                );
                setState(() {});
              }
            },
            child: const Text('Enregistrer'),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Réinitialiser le PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Entrez votre PIN actuel pour réinitialiser:'),
            const SizedBox(height: 16),
            TextField(
              controller: currentPinController,
              decoration: InputDecoration(
                labelText: 'PIN actuel',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.lock),
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
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_configService.verifyPinCode(currentPinController.text)) {
                Navigator.pop(context);
                _showSetPinDialog(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN incorrect'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Vérifier'),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncSettingsCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Auto Sync Switch
          SwitchListTile(
            title: const Text('Synchronisation automatique'),
            subtitle: const Text('Synchroniser automatiquement cuando en ligne'),
            value: _autoSync,
            activeColor: AppTheme.primaryOrange,
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
          const Divider(height: 1),
          // Sync Interval
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.timer, color: AppTheme.primaryOrange),
            ),
            title: const Text('Intervalle de synchronisation'),
            subtitle: Text('Toutes les $_syncInterval minutes'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                value: _syncInterval,
                underline: const SizedBox(),
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
          ),
          const Divider(height: 1),
          // Sync Now
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.sync, color: Colors.blue),
            ),
            title: const Text('Synchroniser maintenant'),
            subtitle: const Text('Forcer la synchronisation'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Provider.of<SyncProvider>(context, listen: false).syncNow();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Synchronisation en cours...')),
              );
            },
          ),
          const Divider(height: 1),
          // Firebase Status
          _buildFirebaseStatusTile(context),
          const Divider(height: 1),
          // Local API Status
          _buildLocalApiStatusTile(context),
        ],
      ),
    );
  }

  Widget _buildLocalApiStatusTile(BuildContext context) {
    final configService = ManacConfigService();
    final isEnabled = configService.getLocalApiEnabled();
    final apiUrl = configService.getLocalApiUrl();
    
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (isEnabled ? Colors.blue : Colors.grey).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          isEnabled ? Icons.dns : Icons.dns_outlined,
          color: isEnabled ? Colors.blue : Colors.grey,
        ),
      ),
      title: const Text('API Locale'),
      subtitle: Text(isEnabled ? apiUrl : 'Désactivée'),
      trailing: TextButton(
        onPressed: () => _showLocalApiConfigDialog(context),
        child: Text(isEnabled ? 'Modifier' : 'Activer'),
      ),
      onTap: () => _showLocalApiConfigDialog(context),
    );
  }

  void _showLocalApiConfigDialog(BuildContext context) {
    final configService = ManacConfigService();
    final urlController = TextEditingController(text: configService.getLocalApiUrl());
    bool isEnabled = configService.getLocalApiEnabled();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.dns, color: AppTheme.primaryOrange),
              SizedBox(width: 12),
              Text('API Locale'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Activer API Locale'),
                value: isEnabled,
                onChanged: (value) {
                  setDialogState(() {
                    isEnabled = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: urlController,
                decoration: InputDecoration(
                  labelText: 'URL de l\'API',
                  hintText: 'http://192.168.1.100:8080',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.link),
                ),
                enabled: isEnabled,
              ),
              const SizedBox(height: 16),
              const Text(
                'API Endpoints à implémenter:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'POST /api/auth/login\n'
                'GET /api/users/me\n'
                'GET /api/health\n'
                'GET/POST /api/stock\n'
                'GET/POST /api/equipements\n'
                'GET/POST /api/emprunts',
                style: TextStyle(fontSize: 11),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                await configService.setLocalApiUrl(urlController.text);
                await configService.setLocalApiEnabled(isEnabled);
                if (mounted) {
                  Navigator.pop(context);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Configuration API Locale sauvegardée')),
                  );
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFirebaseStatusTile(BuildContext context) {
    return FutureBuilder<bool>(
      future: FirebaseService.checkConnection(),
      builder: (context, snapshot) {
        final isConnected = snapshot.data ?? false;
        return ListTile(
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isConnected ? Colors.green : Colors.orange).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isConnected ? Icons.cloud_done : Icons.cloud_off,
              color: isConnected ? Colors.green : Colors.orange,
            ),
          ),
          title: const Text('Firebase'),
          subtitle: Text(isConnected ? 'Connecté à Firebase' : 'Non connecté - Configurez pour sync'),
          trailing: isConnected 
              ? const Icon(Icons.check_circle, color: Colors.green)
              : TextButton(
                  onPressed: () => _showFirebaseConfigDialog(context),
                  child: const Text('Configurer'),
                ),
          onTap: () => _showFirebaseConfigDialog(context),
        );
      },
    );
  }

  void _showFirebaseConfigDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.cloud, color: AppTheme.primaryOrange),
            SizedBox(width: 12),
            Text('Configuration Firebase'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pour activer la synchronisation:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text('1. Créez un projet sur firebase.google.com'),
            SizedBox(height: 8),
            Text('2. Activez Realtime Database'),
            SizedBox(height: 8),
            Text('3. Configurez les règles en lecture/écriture'),
            SizedBox(height: 16),
            Text(
              'Projet Firebase actuel: manac-7339f',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 16),
            Text(
              'Allez dans Sync Status pour tester la connexion.',
              style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SyncStatusScreen()),
              );
            },
            child: const Text('État sync'),
          ),
        ],
      ),
    );
  }

  Widget _buildAppSettingsCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Language
          _buildSettingsTile(
            icon: Icons.language,
            title: 'Langue / Language',
            subtitle: _languageService.currentLanguageName,
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLanguageDialog(context),
          ),
          const Divider(height: 1),
          // Theme
          _buildSettingsTile(
            icon: Icons.palette,
            title: 'Thème',
            subtitle: _themeService.themeModeName == 'light' ? 'Mode clair' :
                       _themeService.themeModeName == 'dark' ? 'Mode sombre' : 'Système',
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemeDialog(context),
          ),
          const Divider(height: 1),
          // Secondary Color
          _buildSettingsTile(
            icon: Icons.color_lens,
            title: 'Couleur secondaire',
            subtitle: 'Personnaliser la couleur d\'accent',
            trailing: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _themeService.secondaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey, width: 2),
              ),
            ),
            onTap: () => _showColorPickerDialog(context),
          ),
          const Divider(height: 1),
          // Notifications
          SwitchListTile(
            secondary: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.notifications, color: Colors.orange),
            ),
            title: const Text('Notifications'),
            subtitle: const Text('Recevoir les alertes de stock'),
            value: _notifications,
            activeColor: AppTheme.primaryOrange,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.language, color: AppTheme.primaryOrange),
            SizedBox(width: 12),
            Text('Choisir la langue'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppLanguageService.supportedLanguages.entries.map((entry) {
            final isSelected = _languageService.locale.languageCode == entry.key;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryOrange.withOpacity(0.1) : null,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppTheme.primaryOrange : Colors.grey[300]!,
                ),
              ),
              child: ListTile(
                leading: Icon(
                  Icons.check_circle,
                  color: isSelected ? AppTheme.primaryOrange : Colors.transparent,
                ),
                title: Text(
                  entry.value,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppTheme.primaryOrange : null,
                  ),
                ),
                onTap: () async {
                  await _languageService.setLanguage(entry.key);
                  if (mounted) Navigator.pop(context);
                  setState(() {});
                },
              ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.palette, color: AppTheme.primaryOrange),
            SizedBox(width: 12),
            Text('Choisir le thème'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption(
              icon: Icons.brightness_auto,
              title: 'Système',
              subtitle: 'Suivre les paramètres du système',
              themeMode: ThemeMode.system,
            ),
            _buildThemeOption(
              icon: Icons.light_mode,
              title: 'Mode clair',
              subtitle: 'Thème clair',
              themeMode: ThemeMode.light,
            ),
            _buildThemeOption(
              icon: Icons.dark_mode,
              title: 'Mode sombre',
              subtitle: 'Thème sombre',
              themeMode: ThemeMode.dark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required ThemeMode themeMode,
  }) {
    final isSelected = _themeService.themeMode == themeMode;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryOrange.withOpacity(0.1) : null,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppTheme.primaryOrange : Colors.grey[300]!,
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? AppTheme.primaryOrange : Colors.grey[600],
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppTheme.primaryOrange : null,
          ),
        ),
        subtitle: Text(subtitle),
        onTap: () async {
          await _themeService.setThemeMode(themeMode);
          if (mounted) Navigator.pop(context);
          setState(() {});
        },
      ),
    );
  }

  void _showColorPickerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.color_lens, color: AppTheme.primaryOrange),
            SizedBox(width: 12),
            Text('Couleur secondaire'),
          ],
        ),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: AppThemeService.availableColors.map((color) {
            final isSelected = _themeService.secondaryColor == color;
            return GestureDetector(
              onTap: () async {
                await _themeService.setSecondaryColor(color);
                if (mounted) Navigator.pop(context);
                setState(() {});
              },
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: Colors.black, width: 3)
                      : Border.all(color: Colors.grey[300]!, width: 1),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 28)
                    : null,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDataManagementCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.cloud_download,
            title: 'Exporter les données',
            subtitle: 'Exporter les données du stock vers un fichier',
            trailing: const Icon(Icons.chevron_right),
            onTap: _exportData,
          ),
          const Divider(height: 1),
          _buildSettingsTile(
            icon: Icons.cloud_upload,
            title: 'Importer les données',
            subtitle: 'Importer les données du stock depuis un fichier',
            trailing: const Icon(Icons.chevron_right),
            onTap: _importData,
          ),
          const Divider(height: 1),
          _buildSettingsTile(
            icon: Icons.delete_forever,
            title: 'Effacer toutes les données',
            subtitle: 'Supprimer toutes les données locales',
            iconColor: Colors.red,
            trailing: const Icon(Icons.chevron_right, color: Colors.red),
            onTap: _showClearDataDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.info,
            title: 'Version',
            subtitle: '1.0.0',
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showVersionDialog(context),
          ),
          const Divider(height: 1),
          _buildSettingsTile(
            icon: Icons.code,
            title: 'Développeur',
            subtitle: 'BAYIGA BOGMIS Ivan / Technical Team',
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showDeveloperDialog(context),
          ),
          const Divider(height: 1),
          _buildSettingsTile(
            icon: Icons.privacy_tip,
            title: 'Politique de confidentialité',
            subtitle: 'Voir la politique de confidentialité',
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
              );
            },
          ),
          const Divider(height: 1),
          _buildSettingsTile(
            icon: Icons.description,
            title: 'Conditions d\'utilisation',
            subtitle: 'Voir les conditions d\'utilisation',
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.info, color: AppTheme.primaryOrange),
            SizedBox(width: 12),
            Text('Informations de version'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manac - Application de Gestion de Stock',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text('Version: 1.0.0'),
            Text('Build: 2026.02.16'),
            SizedBox(height: 12),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.code, color: AppTheme.primaryOrange),
            SizedBox(width: 12),
            Text('Équipe de développement'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.primaryOrange,
                  child: Icon(Icons.person, size: 30, color: Colors.white),
                ),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BAYIGA BOGMIS Ivan',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text('Technical Team'),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),
            Text('Développé avec Flutter et Firebase'),
            SizedBox(height: 8),
            Text(
              'Pour toute question technique, contacter l\'administrateur.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).signOut();
              Navigator.pop(context);
            },
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 12),
            Text('Effacer toutes les données'),
          ],
        ),
        content: const Text(
          'Cela supprimera toutes les données locales, y compris les articles en stock, les activités et la file de synchronisation. '
          'Cette action ne peut pas être annulée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              LocalStorageService.clearAllData();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Toutes les données ont été effacées'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Effacer'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Get all data from local storage
      final equipment = LocalStorageService.getAllEquipment();
      final stockItems = LocalStorageService.getAllStockItems();
      final checkouts = LocalStorageService.getAllCheckouts();
      final activities = LocalStorageService.getRecentActivities(limit: 500);
      
      // Create export data
      final exportData = {
        'exportDate': DateTime.now().toIso8601String(),
        'appVersion': '1.0.0',
        'equipment': equipment.map((e) => e.toMap()).toList(),
        'stockItems': stockItems.map((s) => s.toMap()).toList(),
        'checkouts': checkouts.map((c) => c.toMap()).toList(),
        'activities': activities.map((a) => a.toMap()).toList(),
      };
      
      // Get downloads directory
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${directory.path}/manac_export_$timestamp.json');
      
      // Write data to file
      await file.writeAsString(jsonEncode(exportData));
      
      // Hide loading
      if (mounted) Navigator.pop(context);
      
      // Share the file
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'Manac Data Export',
        ),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Données exportées avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'exportation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _importData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.cloud_upload, color: AppTheme.primaryOrange),
            SizedBox(width: 12),
            Text('Importer des données'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pour importer des données, placez un fichier JSON dans le dossier Documents de l\'application.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            SizedBox(height: 16),
            Text(
              'Format attendu: JSON avec les données de stock.',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fonctionnalité d\'import en cours de développement'),
                ),
              );
            },
            child: const Text('Importer'),
          ),
        ],
      ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(_isSignUp ? 'Créer un compte' : 'Se connecter'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isSignUp)
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nom',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            if (_isSignUp) const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                prefixIcon: const Icon(Icons.lock),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
          child: Text(_isSignUp ? 'Déjà un compte?' : 'Créer un compte'),
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
              : Text(_isSignUp ? 'S\'inscrire' : 'Connexion'),
        ),
      ],
    );
  }
}
