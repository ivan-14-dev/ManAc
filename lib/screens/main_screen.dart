import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/equipment_provider.dart';
import '../providers/sync_provider.dart';
import '../services/connectivity_service.dart';
import 'equipment_checkout_screen.dart';
import 'equipment_return_screen.dart';
import 'equipment_list_screen.dart';
import 'daily_report_screen.dart';
import 'sync_status_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const EquipmentListScreen(),
    const EquipmentCheckoutScreen(),
    const EquipmentReturnScreen(),
    const DailyReportScreen(),
    const SyncStatusScreen(),
    const SettingsScreen(),
  ];

  final List<String> _titles = [
    'Equipment List',
    'Checkout',
    'Return',
    'Daily Report',
    'Sync Status',
    'Settings',
  ];

  final List<IconData> _icons = [
    Icons.inventory,
    Icons.outbound,
    Icons.assignment_return,
    Icons.assessment,
    Icons.sync,
    Icons.settings,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: [
          // Connection status indicator
          Consumer<ConnectivityService>(
            builder: (context, connectivity, child) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Icon(
                  connectivity.isConnected 
                      ? Icons.wifi 
                      : Icons.wifi_off,
                  color: connectivity.isConnected 
                      ? Colors.green 
                      : Colors.red,
                ),
              );
            },
          ),
          // Sync pending indicator
          Consumer<SyncProvider>(
            builder: (context, sync, child) {
              if (sync.pendingSyncCount > 0) {
                return Badge(
                  label: Text('${sync.pendingSyncCount}'),
                  child: const Icon(Icons.cloud_upload),
                );
              }
              return const Icon(Icons.cloud_done);
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          // Side navigation for larger screens
          NavigationRail(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: _titles.asMap().entries.map((entry) {
              return NavigationRailDestination(
                icon: Icon(_icons[entry.key]),
                label: Text(entry.value),
              );
            }).toList(),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // Main content
          Expanded(
            child: _pages[_currentIndex],
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: _titles.asMap().entries.map((entry) {
          return NavigationDestination(
            icon: Icon(_icons[entry.key]),
            label: entry.value,
          );
        }).toList(),
      ),
    );
  }
}
