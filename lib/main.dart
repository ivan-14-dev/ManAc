// ========================================
// Application principale ManAc - Gestion de Stock
// Point d'entrée de l'application Flutter
// ========================================

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'firebase_options.dart';
import 'callback_dispatcher.dart';
import 'services/local_storage_service.dart';
import 'services/connectivity_service.dart';
import 'services/app_theme_service.dart';
import 'providers/stock_provider.dart';
import 'providers/equipment_provider.dart';
import 'providers/sync_provider.dart';
import 'providers/auth_provider.dart' as app_auth;
import 'screens/main_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/intro_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/pin_login_screen.dart';
import 'services/manac_config_service.dart';
import 'theme/app_theme.dart';

// Fonction principale asynchrone - point d'entrée de l'application
void main() async {
  // Initialiser les liaisons Flutter avant tout code async
  WidgetsFlutterBinding.ensureInitialized();
  
  // Charger les variables d'environnement depuis .env
  // Ignore les erreurs car les valeurs par défaut sont utilisées si .env n'existe pas
  try {
    await dotenv.load(
      fileName: kIsWeb ? '.env' : '.env',
    );
  } catch (e) {
    // On continue sans les variables d'environnement
    // Les valeurs par défaut dans firebase_options seront utilisées
    debugPrint('Note: .env non chargé - utilisation des valeurs par défaut');
  }
  
  // Initialiser Firebase avec les options de la plateforme
  // Vérifier si Firebase est déjà initialisé pour éviter les erreurs lors du hot reload
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    // Firebase pourrait déjà être initialisé, on continue
    debugPrint('Firebase initialization: $e');
  }
  
  // Initialiser le stockage local pour les données hors ligne
  await LocalStorageService.init();
  
  // Initialiser le service de thème
  await AppThemeService().init();
  
  // Initialiser Workmanager pour la synchronisation en arrière-plan
  Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false,
  );

  // Enregistrer une tâche périodique de synchronisation (toutes les 15 minutes)
  Workmanager().registerPeriodicTask(
    'periodic-sync',
    'syncTask',
    frequency: const Duration(minutes: 15),
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
  );
  
  // Lancer l'application
  runApp(const ManacApp());
}

// Widget principal de l'application
class ManacApp extends StatefulWidget {
  const ManacApp({super.key});

  @override
  State<ManacApp> createState() => _ManacAppState();
}

// État de l'application principale
class _ManacAppState extends State<ManacApp> {
  // Indicateur d'initialisation terminée
  bool _isInitialized = false;
  bool _showIntro = false;
  bool _showOnboarding = false;
  bool _showPinLogin = false;
  final ManacConfigService _configService = ManacConfigService();
  final AppThemeService _themeService = AppThemeService();

  @override
  void initState() {
    super.initState();
    // Vérifier l'authentification après la première frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFirstTime();
    });
  }

  // Vérifier si premier lancement
  Future<void> _checkFirstTime() async {
    final isOfflineMode = _configService.isOfflineMode();
    final isLoggedIn = _configService.isLoggedIn();
    final hasPin = _configService.hasPinCode();
    
    // Vérifier si l'utilisateur a déjà vu l'onboarding
    final hasSeenOnboarding = LocalStorageService.getSetting('has_seen_onboarding', defaultValue: false);
    
    setState(() {
      // Désactiver définitivement l'intro et l'onboarding
      // L'utilisateur peut les voir via les paramètres s'il le souhaite
      _showIntro = false;
      _showOnboarding = false;
      
      // Si déjà connecté ET a un PIN, montrer l'écran de connexion PIN
      _showPinLogin = isLoggedIn && hasPin;
      _isInitialized = true;
    });
  }

  // Callback appelé quand l'initialisation est terminée
  void _onInitialized() {
    setState(() {
      _isInitialized = true;
    });
  }

  // Naviguer vers l'écran approprié
  Widget _getHomeScreen() {
    // Si premier lancement, montrer l'intro (désactivé maintenant)
    // L'intro et l'onboarding ont été désactivés
    
    // Si utilisateur connecté avec PIN, montrer l'écran de connexion PIN
    if (_showPinLogin) {
      return const PinLoginScreen();
    }
    
    // Retourner le login ou main screen selon l'authentification
    return Consumer<app_auth.AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isAuthenticated) {
          return const MainScreen();
        }
        return const LoginScreen();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Si pas encore initialisé, afficher l'écran de démarrage
    if (!_isInitialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: SplashScreen(onInitialized: _onInitialized),
      );
    }

    // Configuration des providers (gestion d'état)
    return MultiProvider(
      providers: [
        // Service de connectivité pour surveiller la connexion internet
        ChangeNotifierProvider(
          create: (_) => ConnectivityService(connectivity: Connectivity()),
        ),
        
        // Provider d'authentification pour la gestion des utilisateurs
        ChangeNotifierProvider(
          create: (_) => app_auth.AuthProvider(),
        ),
        
        // Provider de stock pour la gestion de l'inventaire
        ChangeNotifierProvider(
          create: (_) => StockProvider(),
        ),
        
        // Provider d'équipements pour la gestion des équipements
        ChangeNotifierProvider(
          create: (_) => EquipmentProvider(),
        ),
        
        // Provider de synchronisation pour la sync avec Firebase
        ChangeNotifierProvider(
          create: (context) => SyncProvider(
            connectivityService: context.read<ConnectivityService>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Manac - Gestion de Stock',
        debugShowCheckedModeBanner: false,
        theme: _themeService.buildLightTheme(),
        darkTheme: _themeService.buildDarkTheme(),
        themeMode: _themeService.themeMode,
        // Naviguer vers l'écran approprié
        home: _getHomeScreen(),
      ),
    );
  }
}
