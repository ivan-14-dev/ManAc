// ========================================
// Application principale ManAc - Gestion de Stock
// Point d'entrée de l'application Flutter
// ========================================

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:workmanager/workmanager.dart';

import 'firebase_options.dart';
import 'callback_dispatcher.dart';
import 'services/local_storage_service.dart';
import 'services/connectivity_service.dart';
import 'providers/stock_provider.dart';
import 'providers/equipment_provider.dart';
import 'providers/sync_provider.dart';
import 'providers/auth_provider.dart' as app_auth;
import 'screens/main_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

// Fonction principale asynchrone - point d'entrée de l'application
void main() async {
  // Initialiser les liaisons Flutter avant tout code async
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser Firebase avec les options de la plateforme
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialiser le stockage local pour les données hors ligne
  await LocalStorageService.init();
  
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

  @override
  void initState() {
    super.initState();
    // Vérifier l'authentification après la première frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuth();
    });
  }

  // Vérifier si l'utilisateur est déjà authentifié
  void _checkAuth() {
    final auth = app_auth.AuthProvider();
    if (auth.isAuthenticated) {
      setState(() {
        _isInitialized = true;
      });
    } else {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  // Callback appelé quand l'initialisation est terminée
  void _onInitialized() {
    setState(() {
      _isInitialized = true;
    });
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
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        // Naviguer selon l'état d'authentification
        home: Consumer<app_auth.AuthProvider>(
          builder: (context, auth, _) {
            if (auth.isAuthenticated) {
              return const MainScreen();
            }
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}
