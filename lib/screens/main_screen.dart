import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/equipment_provider.dart';
import '../providers/sync_provider.dart';
import '../services/connectivity_service.dart';
import '../theme/app_theme.dart';
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
    'Equipment',
    'Checkout',
    'Return',
    'Reports',
    'Sync',
    'Settings',
  ];

  final List<IconData> _icons = [
    Icons.inventory_2_outlined,
    Icons.outbound,
    Icons.assignment_return,
    Icons.assessment_outlined,
    Icons.sync,
    Icons.settings_outlined,
  ];

  final List<IconData> _selectedIcons = [
    Icons.inventory_2,
    Icons.outbound,
    Icons.assignment_return,
    Icons.assessment,
    Icons.sync,
    Icons.settings,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Gradient App Bar
          _buildGradientAppBar(context),
          
          // Main Content
          Expanded(
            child: _pages[_currentIndex],
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildGradientAppBar(BuildContext context) {
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Logo and Title
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.inventory,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'ManAc',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      _titles[_currentIndex],
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Connection status
              Consumer<ConnectivityService>(
                builder: (context, connectivity, child) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          connectivity.isConnected 
                              ? Icons.wifi 
                              : Icons.wifi_off,
                          color: connectivity.isConnected 
                              ? Colors.greenAccent 
                              : Colors.redAccent,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          connectivity.isConnected ? 'Online' : 'Offline',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              
              const SizedBox(width: 8),
              
              // Sync indicator
              Consumer<SyncProvider>(
                builder: (context, sync, child) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: sync.pendingSyncCount > 0 
                          ? Colors.orange.withOpacity(0.3)
                          : Colors.green.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (sync.pendingSyncCount > 0) ...[
                          Badge(
                            smallSize: 16,
                            label: Text(
                              '${sync.pendingSyncCount}',
                              style: const TextStyle(fontSize: 10),
                            ),
                            child: const Icon(
                              Icons.cloud_upload,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ] else ...[
                          const Icon(
                            Icons.cloud_done,
                            color: Colors.greenAccent,
                            size: 18,
                          ),
                        ],
                      ],
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

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_titles.length, (index) {
              final isSelected = _currentIndex == index;
              return _buildNavItem(
                icon: isSelected ? _selectedIcons[index] : _icons[index],
                label: _titles[index],
                isSelected: isSelected,
                onTap: () => _onItemTapped(index),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.primaryOrange.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryOrange : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.primaryOrange : Colors.grey[600],
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
}
