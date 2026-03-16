import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sync_provider.dart';
import '../providers/auth_provider.dart';
import '../services/connectivity_service.dart';
import '../services/local_storage_service.dart';

class SyncStatusScreen extends StatelessWidget {
  const SyncStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<SyncProvider, AuthProvider, ConnectivityService>(
      builder: (context, syncProvider, authProvider, connectivity, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Synchronisation'),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Connection status card
                _ConnectionStatusCard(
                  isOnline: connectivity.isConnected,
                  lastConnected: connectivity.lastConnectedAt,
                  lastDisconnected: connectivity.lastDisconnectedAt,
                ),
                const SizedBox(height: 16),
                // Sync status card
                _SyncStatusCard(
                  isSyncing: syncProvider.isSyncing,
                  syncStatus: syncProvider.syncStatus,
                  lastSyncTime: syncProvider.lastSyncTime,
                  pendingCount: syncProvider.pendingSyncCount,
                ),
                const SizedBox(height: 16),
                // Sync actions
                _SyncActionsCard(
                  isOnline: connectivity.isConnected,
                  isSyncing: syncProvider.isSyncing,
                  onSyncNow: syncProvider.syncNow,
                  onFullSync: syncProvider.fullSync,
                ),
                const SizedBox(height: 16),
                // User info card
                if (authProvider.isAuthenticated) ...[
                  _UserInfoCard(
                    userName: authProvider.userName ?? 'Unknown',
                    userId: authProvider.userId ?? '',
                  ),
                  const SizedBox(height: 16),
                ],
                // Statistics card
                _StatisticsCard(),
                const SizedBox(height: 16),
                // Pending sync items
                _PendingSyncItemsCard(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ConnectionStatusCard extends StatelessWidget {
  final bool isOnline;
  final DateTime? lastConnected;
  final DateTime? lastDisconnected;

  const _ConnectionStatusCard({
    required this.isOnline,
    this.lastConnected,
    this.lastDisconnected,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isOnline ? Icons.wifi : Icons.wifi_off,
                  color: isOnline ? Colors.green : Colors.red,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isOnline ? Colors.green : Colors.red,
                      ),
                    ),
                    Text(
                      isOnline
                          ? 'Connected to internet'
                          : 'No internet connection',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
            if (lastConnected != null && isOnline) ...[
              const SizedBox(height: 16),
              Divider(color: Colors.grey[300]),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Connected since: ${_formatDateTime(lastConnected!)}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
            if (lastDisconnected != null && !isOnline) ...[
              const SizedBox(height: 16),
              Divider(color: Colors.grey[300]),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Disconnected at: ${_formatDateTime(lastDisconnected!)}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class _SyncStatusCard extends StatelessWidget {
  final bool isSyncing;
  final String syncStatus;
  final DateTime? lastSyncTime;
  final int pendingCount;

  const _SyncStatusCard({
    required this.isSyncing,
    required this.syncStatus,
    this.lastSyncTime,
    required this.pendingCount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                isSyncing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        pendingCount > 0 ? Icons.sync_problem : Icons.check_circle,
                        color: pendingCount > 0 ? Colors.orange : Colors.green,
                        size: 32,
                      ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      syncStatus,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (lastSyncTime != null)
                      Text(
                        'Last sync: ${_formatDateTime(lastSyncTime!)}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                  ],
                ),
              ],
            ),
            if (pendingCount > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.pending, color: Colors.orange[800], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '$pendingCount items pending sync',
                      style: TextStyle(
                        color: Colors.orange[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class _SyncActionsCard extends StatelessWidget {
  final bool isOnline;
  final bool isSyncing;
  final VoidCallback onSyncNow;
  final VoidCallback onFullSync;

  const _SyncActionsCard({
    required this.isOnline,
    required this.isSyncing,
    required this.onSyncNow,
    required this.onFullSync,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sync Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isOnline && !isSyncing ? onSyncNow : null,
                    icon: isSyncing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync),
                    label: const Text('Sync Now'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isOnline && !isSyncing ? onFullSync : null,
                    icon: const Icon(Icons.cloud_download),
                    label: const Text('Full Sync'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              isOnline
                  ? 'Tap "Sync Now" to sync pending changes'
                  : 'Connect to internet to sync data',
              style: TextStyle(
                color: isOnline ? Colors.grey[600] : Colors.red,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserInfoCard extends StatelessWidget {
  final String userName;
  final String userId;

  const _UserInfoCard({required this.userName, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue[100],
              child: const Icon(Icons.person, color: Colors.blue),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'ID: ${userId.substring(0, 8)}...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.verified_user, color: Colors.green),
          ],
        ),
      ),
    );
  }
}

class _StatisticsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final stockItems = LocalStorageService.getAllStockItems();
    final pendingSync = LocalStorageService.getPendingSyncItems();
    final activities = LocalStorageService.getRecentActivities(limit: 100);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _StatisticItem(
                  icon: Icons.inventory,
                  value: stockItems.length.toString(),
                  label: 'Total Items',
                  color: Colors.blue,
                ),
                _StatisticItem(
                  icon: Icons.pending,
                  value: pendingSync.length.toString(),
                  label: 'Pending Sync',
                  color: Colors.orange,
                ),
                _StatisticItem(
                  icon: Icons.history,
                  value: activities.length.toString(),
                  label: 'Activities',
                  color: Colors.purple,
                ),
                _StatisticItem(
                  icon: Icons.sync_problem,
                  value: pendingSync
                      .where((i) => i.retryCount > 0)
                      .length
                      .toString(),
                  label: 'Failed',
                  color: Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatisticItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatisticItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PendingSyncItemsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final pendingItems = LocalStorageService.getPendingSyncItems();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pending Sync Queue',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${pendingItems.length} items',
                  style: TextStyle(
                    color: pendingItems.isEmpty ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (pendingItems.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 48),
                    const SizedBox(height: 8),
                    Text(
                      'All items synced!',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            else
              ...pendingItems.take(5).map((item) {
                return ListTile(
                  leading: Icon(
                    _getActionIcon(item.action),
                    color: _getActionColor(item.action),
                  ),
                  title: Text('${item.action.toUpperCase()} - ${item.collection}'),
                  subtitle: Text(
                    'Created: ${_formatDateTime(item.createdAt)}',
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: item.retryCount > 0
                      ? Badge(
                          label: Text('${item.retryCount}'),
                          child: const Icon(Icons.error),
                        )
                      : null,
                );
              }).toList(),
            if (pendingItems.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '... and ${pendingItems.length - 5} more',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'create':
        return Icons.add;
      case 'update':
        return Icons.edit;
      case 'delete':
        return Icons.delete;
      default:
        return Icons.sync;
    }
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'create':
        return Colors.green;
      case 'update':
        return Colors.blue;
      case 'delete':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
