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
import 'providers/sync_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/main_screen.dart';

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

class ManacApp extends StatelessWidget {
  const ManacApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Connectivity Service
        ChangeNotifierProvider(
          create: (_) => ConnectivityService(connectivity: Connectivity()),
        ),
        
        // Auth Provider
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),
        
        // Stock Provider
        ChangeNotifierProvider(
          create: (_) => StockProvider(),
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
        theme: ThemeData(
          primarySwatch: Colors.blue,
          primaryColor: const Color(0xFF1976D2),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1976D2),
            secondary: const Color(0xFF43A047),
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1976D2),
            foregroundColor: Colors.white,
            elevation: 2,
          ),
          cardTheme: CardThemeData(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.grey[100],
          ),
        ),
        home: const MainScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
