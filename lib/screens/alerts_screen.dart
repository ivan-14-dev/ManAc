import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/equipment_provider.dart';
import '../providers/stock_provider.dart';
import '../services/local_storage_service.dart';
import '../services/app_language_service.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final language = AppLanguageService();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(language.translate('alerts')),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer2<EquipmentProvider, StockProvider>(
        builder: (context, equipmentProvider, stockProvider, child) {
          // Get pending returns (active checkouts)
          final pendingReturns = equipmentProvider.activeCheckouts;
          
          // Get low stock items
          final lowStockItems = stockProvider.stockItems
              .where((item) => item.isLowStock)
              .toList();
          
          final hasAlerts = pendingReturns.isNotEmpty || lowStockItems.isNotEmpty;
          
          if (!hasAlerts) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    language.translate('no_alerts'),
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }
          
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Pending Returns Section
              if (pendingReturns.isNotEmpty) ...[
                _buildSectionHeader(
                  language.translate('pending_returns'),
                  pendingReturns.length,
                  Icons.assignment_return,
                  Colors.orange,
                ),
                const SizedBox(height: 8),
                ...pendingReturns.map((checkout) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange.withOpacity(0.2),
                      child: const Icon(Icons.assignment_return, color: Colors.orange),
                    ),
                    title: Text(checkout.equipmentName),
                    subtitle: Text(
                      '${checkout.borrowerName} - ${checkout.destinationRoom}',
                    ),
                    trailing: Text(
                      '${checkout.quantity}x',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                )),
                const SizedBox(height: 16),
              ],
              
              // Low Stock Section
              if (lowStockItems.isNotEmpty) ...[
                _buildSectionHeader(
                  language.translate('low_stock'),
                  lowStockItems.length,
                  Icons.inventory_2,
                  Colors.red,
                ),
                const SizedBox(height: 8),
                ...lowStockItems.map((item) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.red.withOpacity(0.2),
                      child: const Icon(Icons.inventory_2, color: Colors.red),
                    ),
                    title: Text(item.name),
                    subtitle: Text(item.category),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${item.quantity}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        Text(
                          'Min: ${item.minQuantity}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
