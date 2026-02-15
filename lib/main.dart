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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize local storage
  await LocalStorageService.init();
  
  // Initialize Workmanager for background sync
  Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false,
  );

  // Start periodic sync
  Workmanager().registerPeriodicTask(
    'periodic-sync',
    'syncTask',
    frequency: const Duration(minutes: 15),
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
  );
  
  runApp(const ManacApp());
}

class ManacApp extends StatefulWidget {
  const ManacApp({super.key});

  @override
  State<ManacApp> createState() => _ManacAppState();
}

class _ManacAppState extends State<ManacApp> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Delay auth check until after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuth();
    });
  }

  void _checkAuth() {
    // Check if user is already authenticated
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

  void _onInitialized() {
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: SplashScreen(onInitialized: _onInitialized),
      );
    }

    return MultiProvider(
      providers: [
        // Connectivity Service
        ChangeNotifierProvider(
          create: (_) => ConnectivityService(connectivity: Connectivity()),
        ),
        
        // Auth Provider
        ChangeNotifierProvider(
          create: (_) => app_auth.AuthProvider(),
        ),
        
        // Stock Provider
        ChangeNotifierProvider(
          create: (_) => StockProvider(),
        ),
        
        // Equipment Provider
        ChangeNotifierProvider(
          create: (_) => EquipmentProvider(),
        ),
        
        // Sync Provider
        ChangeNotifierProvider(
          create: (context) => SyncProvider(
            connectivityService: context.read<ConnectivityService>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Manac - Stock Management',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
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
