// ========================================
// Service de langue / Language Service
// Gère le multilingue (Français, Anglais)
// ========================================

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLanguageService {
  static final AppLanguageService _instance = AppLanguageService._internal();
  factory AppLanguageService() => _instance;
  AppLanguageService._internal();

  static AppLanguageService get instance => _instance;

  static const String _languageKey = 'app_language';
  
  SharedPreferences? _prefs;
  
  // Supported languages
  static const Map<String, String> supportedLanguages = {
    'fr': 'Français',
    'en': 'English',
  };

  // Current locale
  Locale _locale = const Locale('fr');

  Locale get locale => _locale;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final savedLanguage = _prefs?.getString(_languageKey) ?? 'fr';
    _locale = Locale(savedLanguage);
  }

  Future<void> setLanguage(String languageCode) async {
    if (supportedLanguages.containsKey(languageCode)) {
      _locale = Locale(languageCode);
      await _prefs?.setString(_languageKey, languageCode);
    }
  }

  String get currentLanguageName {
    return supportedLanguages[_locale.languageCode] ?? 'Français';
  }

  // Translations
  static Map<String, Map<String, String>> get _translations => {
    'fr': {
      // General
      'app_name': 'Manac',
      'save': 'Enregistrer',
      'cancel': 'Annuler',
      'confirm': 'Confirmer',
      'delete': 'Supprimer',
      'edit': 'Modifier',
      'close': 'Fermer',
      'next': 'Suivant',
      'back': 'Retour',
      'done': 'Terminé',
      'yes': 'Oui',
      'no': 'Non',
      'ok': 'OK',
      'error': 'Erreur',
      'success': 'Succès',
      'loading': 'Chargement...',
      
      // Settings
      'settings': 'Paramètres',
      'account': 'Compte',
      'profile': 'Profil',
      'name': 'Nom',
      'email': 'Email',
      'phone': 'Téléphone',
      'department': 'Département',
      'pin_code': 'Code PIN',
      'change_pin': 'Changer le PIN',
      'reset_pin': 'Réinitialiser le PIN',
      'set_pin': 'Définir le PIN',
      'sign_in': 'Connexion',
      'sign_out': 'Déconnexion',
      'sync_settings': 'Synchronisation',
      'auto_sync': 'Synchronisation automatique',
      'sync_interval': 'Intervalle de synchronisation',
      'app_settings': 'Application',
      'notifications': 'Notifications',
      'language': 'Langue',
      'theme': 'Thème',
      'dark_mode': 'Mode sombre',
      'light_mode': 'Mode clair',
      'secondary_color': 'Couleur secondaire',
      'data_management': 'Gestion des données',
      'export_data': 'Exporter les données',
      'import_data': 'Importer les données',
      'clear_data': 'Effacer les données',
      'about': 'À propos',
      'version': 'Version',
      'developer': 'Développeur',
      'privacy_policy': 'Politique de confidentialité',
      'terms_of_service': 'Conditions d\'utilisation',
      
      // Notifications/Alerts
      'alerts': 'Alertes',
      'pending_returns': 'Retours en attente',
      'low_stock': 'Stock faible',
      'no_alerts': 'Aucune alerte',
      
      // Onboarding
      'welcome': 'Bienvenue',
      'get_started': 'Commencer',
      'skip': 'Passer',
      'previous': 'Précédent',
      
      // Intro Pages
      'Stock Management': 'Gestion de Stock',
      'Easily manage your equipment inventory with real-time tracking.': 'Gérez facilement votre inventaire d\'équipements avec un suivi en temps réel.',
      'Borrow & Return': 'Emprunt & Retour',
      'Quickly record equipment borrow and returns with Flash mode.': 'Enregistrez les emprunts et retours d\'équipements rapidement avec le mode Flash.',
      'Synchronization': 'Synchronisation',
      'Work online or offline with automatic synchronization.': 'Travaillez en ligne ou hors ligne avec synchronisation automatique.',
      'Alerts & Notifications': 'Alertes & Notifications',
      'Receive alerts for pending returns and low stock.': 'Recevez des alertes pour les retours en attente et le stock faible.',
      'Reports & Exports': 'Rapports & Exports',
      'Generate PDF reports and export your data easily.': 'Générez des rapports PDF et exportez vos données facilement.',
      
      // Onboarding Pages
      'onboarding_1_title': 'Collecte des données',
      'onboarding_1_desc': 'Manac collecte uniquement les informations nécessaires au fonctionnement de l\'application, notamment :\n\n• Adresse email (authentification)\n• Données de gestion de stock\n• Données de synchronisation\n\nAucune donnée non nécessaire n\'est collectée.',
      
      'onboarding_2_title': 'Stockage des données',
      'onboarding_2_desc': 'Les données sont stockées :\n\n📱 Local sur l\'appareil (mode hors ligne)\n☁️ Serveurs Firebase (Cloud Firestore)\n\nSynchronisation automatique quand connecté.',
      
      'onboarding_3_title': 'Sécurité et protection',
      'onboarding_3_desc': 'Nous mettons en œuvre :\n\n✓ Authentification sécurisée\n✓ Règles de sécurité Firestore\n✓ Protection des accès\n✓ Isolation des données par utilisateur',
      
      'onboarding_4_title': 'Partage des données',
      'onboarding_4_desc': 'Manac :\n\n❌ Ne vend pas les données\n❌ Ne partage pas à des tiers\n✅ Utilise uniquement Firebase pour le fonctionnement',
      
      'onboarding_5_title': 'Responsabilité',
      'onboarding_5_desc': 'L\'utilisateur est responsable de :\n\n• La confidentialité de son mot de passe\n• L\'exactitude des données saisies\n• L\'utilisation conforme à la loi\n\nManac ne peut être tenu responsable des pertes.',
      
      'accept_terms': 'J\'accepte les conditions d\'utilisation',
      'privacy_accepted': 'Politique de confidentialité acceptée',
    },
    'en': {
      // General
      'app_name': 'Manac',
      'save': 'Save',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'delete': 'Delete',
      'edit': 'Edit',
      'close': 'Close',
      'next': 'Next',
      'back': 'Back',
      'done': 'Done',
      'yes': 'Yes',
      'no': 'No',
      'ok': 'OK',
      'error': 'Error',
      'success': 'Success',
      'loading': 'Loading...',
      
      // Settings
      'settings': 'Settings',
      'account': 'Account',
      'profile': 'Profile',
      'name': 'Name',
      'email': 'Email',
      'phone': 'Phone',
      'department': 'Department',
      'pin_code': 'PIN Code',
      'change_pin': 'Change PIN',
      'reset_pin': 'Reset PIN',
      'set_pin': 'Set PIN',
      'sign_in': 'Sign In',
      'sign_out': 'Sign Out',
      'sync_settings': 'Sync Settings',
      'auto_sync': 'Auto Sync',
      'sync_interval': 'Sync Interval',
      'app_settings': 'App Settings',
      'notifications': 'Notifications',
      'language': 'Language',
      'theme': 'Theme',
      'dark_mode': 'Dark Mode',
      'light_mode': 'Light Mode',
      'secondary_color': 'Secondary Color',
      'data_management': 'Data Management',
      'export_data': 'Export Data',
      'import_data': 'Import Data',
      'clear_data': 'Clear Data',
      'about': 'About',
      'version': 'Version',
      'developer': 'Developer',
      'privacy_policy': 'Privacy Policy',
      'terms_of_service': 'Terms of Service',
      
      // Notifications/Alerts
      'alerts': 'Alerts',
      'pending_returns': 'Pending Returns',
      'low_stock': 'Low Stock',
      'no_alerts': 'No alerts',
      
      // Onboarding
      'welcome': 'Welcome',
      'get_started': 'Get Started',
      'skip': 'Skip',
      'previous': 'Previous',
      
      // Intro Pages
      'Stock Management': 'Stock Management',
      'Easily manage your equipment inventory with real-time tracking.': 'Easily manage your equipment inventory with real-time tracking.',
      'Borrow & Return': 'Borrow & Return',
      'Quickly record equipment borrow and returns with Flash mode.': 'Quickly record equipment borrow and returns with Flash mode.',
      'Synchronization': 'Synchronization',
      'Work online or offline with automatic synchronization.': 'Work online or offline with automatic synchronization.',
      'Alerts & Notifications': 'Alerts & Notifications',
      'Receive alerts for pending returns and low stock.': 'Receive alerts for pending returns and low stock.',
      'Reports & Exports': 'Reports & Exports',
      'Generate PDF reports and export your data easily.': 'Generate PDF reports and export your data easily.',
      
      // Onboarding Pages
      'onboarding_1_title': 'Data Collection',
      'onboarding_1_desc': 'Manac only collects information necessary for the app to function, including:\n\n• Email address (authentication)\n• Stock management data\n• Synchronization data\n\nNo unnecessary data is collected.',
      
      'onboarding_2_title': 'Data Storage',
      'onboarding_2_desc': 'Data is stored:\n\n📱 Locally on device (offline mode)\n☁️ Firebase servers (Cloud Firestore)\n\nAutomatic sync when connected.',
      
      'onboarding_3_title': 'Security & Protection',
      'onboarding_3_desc': 'We implement:\n\n✓ Secure authentication\n✓ Firestore security rules\n✓ Access protection\n✓ User data isolation',
      
      'onboarding_4_title': 'Data Sharing',
      'onboarding_4_desc': 'Manac:\n\n❌ Does not sell data\n❌ Does not share with third parties\n✅ Uses only Firebase for functionality',
      
      'onboarding_5_title': 'Responsibility',
      'onboarding_5_desc': 'The user is responsible for:\n\n• Password confidentiality\n• Data accuracy\n• Lawful use\n\nManac cannot be held liable for losses.',
      
      'accept_terms': 'I accept the terms of use',
      'privacy_accepted': 'Privacy policy accepted',
    },
  };

  String translate(String key) {
    return _translations[_locale.languageCode]?[key] ?? 
           _translations['fr']?[key] ?? 
           key;
  }

  // Alias for translate for easier use
  String getText(String key) => translate(key);

  String translateWithParams(String key, Map<String, String> params) {
    String result = translate(key);
    params.forEach((paramKey, value) {
      result = result.replaceAll('{$paramKey}', value);
    });
    return result;
  }
}
