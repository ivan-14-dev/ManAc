import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import '../services/sync_service.dart';
import '../services/connectivity_service.dart';
import '../services/local_storage_service.dart';

class SyncProvider with ChangeNotifier {
  final SyncService _syncService = SyncService();
  final ConnectivityService _connectivityService;
  
  bool _isSyncing = false;
  bool _isOnline = true;
  int _pendingSyncCount = 0;
  DateTime? _lastSyncTime;
  String _syncStatus = 'Synced';

  bool get isSyncing => _isSyncing;
  bool get isOnline => _isOnline;
  int get pendingSyncCount => _pendingSyncCount;
  DateTime? get lastSyncTime => _lastSyncTime;
  String get syncStatus => _syncStatus;

  SyncProvider({required ConnectivityService connectivityService})
      : _connectivityService = connectivityService {
    _init();
  }

  void _init() {
    _connectivityService.addListener(_handleConnectivityChange);
    _isOnline = _connectivityService.isConnected;
    _updatePendingSyncCount();
  }

  void _handleConnectivityChange() {
    _isOnline = _connectivityService.isConnected;
    notifyListeners();

    if (_isOnline) {
      // Auto sync when coming online
      syncNow();
    }
  }

  void _updatePendingSyncCount() {
    _pendingSyncCount = LocalStorageService.getPendingSyncItems().length;
    notifyListeners();
  }

  Future<void> syncNow() async {
    if (_isSyncing || !_isOnline) return;

    _isSyncing = true;
    _syncStatus = 'Syncing...';
    notifyListeners();

    try {
      await _syncService.processSyncQueue();
      _syncStatus = 'Synced';
      _lastSyncTime = DateTime.now();
      _updatePendingSyncCount();
    } catch (e) {
      _syncStatus = 'Sync failed';
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> fullSync() async {
    if (_isSyncing || !_isOnline) return;

    _isSyncing = true;
    _syncStatus = 'Full sync...';
    notifyListeners();

    try {
      await _syncService.fullSyncFromCloud();
      _syncStatus = 'Synced';
      _lastSyncTime = DateTime.now();
      _updatePendingSyncCount();
    } catch (e) {
      _syncStatus = 'Full sync failed';
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  void startPeriodicSync() {
    // Schedule periodic sync every 15 minutes
    Workmanager().registerPeriodicTask(
      'periodic-sync',
      'syncTask',
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }

  void stopPeriodicSync() {
    Workmanager().cancelAll();
  }

  @override
  void dispose() {
    _connectivityService.removeListener(_handleConnectivityChange);
    super.dispose();
  }
}
