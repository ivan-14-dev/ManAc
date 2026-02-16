// ========================================
// Service de synchronisation
// Gère la file d'attente des opérations à synchroniser avec Firebase
// ========================================

import 'package:uuid/uuid.dart';
import '../models/stock_item.dart';
import '../models/stock_movement.dart';
import '../models/sync_queue_item.dart';
import '../models/activity.dart';
import '../models/equipment_checkout.dart';
import 'local_storage_service.dart';
import 'firebase_service.dart';

// Classe de service pour la synchronisation des données
class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  // Add item to sync queue
  static Future<void> queueForSync({
    required String action,
    required String collection,
    required Map<String, dynamic> data,
  }) async {
    final syncItem = SyncQueueItem(
      id: const Uuid().v4(),
      action: action,
      collection: collection,
      data: data,
    );
    await LocalStorageService.addToSyncQueue(syncItem);
  }

  // Process sync queue
  Future<bool> processSyncQueue() async {
    if (_isSyncing) return false;
    _isSyncing = true;

    final pendingItems = LocalStorageService.getPendingSyncItems();
    int failCount = 0;

    for (final item in pendingItems) {
      try {
        await _processSyncItem(item);
        await LocalStorageService.removeFromSyncQueue(item.id);
      } catch (e) {
        await LocalStorageService.updateSyncItem(
          item.copyWith(
            retryCount: item.retryCount + 1,
            error: e.toString(),
          ),
        );
        failCount++;
      }
    }

    _isSyncing = false;
    return failCount == 0;
  }

  Future<void> _processSyncItem(SyncQueueItem item) async {
    switch (item.collection) {
      case 'stock_items':
        await _syncStockItem(item);
        break;
      case 'stock_movements':
        await _syncMovement(item);
        break;
      case 'activities':
        await _syncActivity(item);
        break;
      case 'equipment_checkouts':
        await _syncCheckout(item);
        break;
      default:
        throw Exception('Unknown collection: ${item.collection}');
    }
  }

  Future<void> _syncStockItem(SyncQueueItem item) async {
    final data = item.data;
    final stockItem = StockItem.fromMap(data);

    if (item.action == 'create') {
      final firebaseId = await FirebaseService.createStockItem(stockItem);
      await LocalStorageService.markItemAsSynced(stockItem.id, firebaseId);
    } else if (item.action == 'update') {
      await FirebaseService.updateStockItem(stockItem);
      await LocalStorageService.markItemAsSynced(stockItem.id, stockItem.firebaseId!);
    } else if (item.action == 'delete') {
      if (stockItem.firebaseId != null) {
        await FirebaseService.deleteStockItem(stockItem.firebaseId!);
      }
    }
  }

  Future<void> _syncMovement(SyncQueueItem item) async {
    final data = item.data;
    final movement = StockMovement.fromMap(data);

    if (item.action == 'create') {
      await FirebaseService.createMovement(movement);
      await LocalStorageService.markMovementAsSynced(movement.id);
    }
  }

  Future<void> _syncActivity(SyncQueueItem item) async {
    final data = item.data;
    final activity = Activity.fromMap(data);

    if (item.action == 'create') {
      await FirebaseService.createActivity(activity);
    }
  }

  // Sync equipment checkouts
  Future<void> _syncCheckout(SyncQueueItem item) async {
    final data = item.data;
    final checkout = EquipmentCheckout.fromMap(data);

    if (item.action == 'create') {
      // For create, check if already exists locally
      final existing = LocalStorageService.getCheckoutById(checkout.id);
      if (existing == null) {
        await LocalStorageService.addCheckout(checkout);
      }
      await LocalStorageService.markCheckoutAsSynced(checkout.id);
    } else if (item.action == 'update') {
      await LocalStorageService.updateCheckout(checkout);
      await LocalStorageService.markCheckoutAsSynced(checkout.id);
    } else if (item.action == 'delete') {
      // Handle delete if needed
    }
  }

  // Full sync from Firebase to local
  Future<void> fullSyncFromCloud() async {
    try {
      // Fetch all stock items from Firebase
      final cloudItems = await FirebaseService.fetchStockItems();
      
      for (final cloudItem in cloudItems) {
        final localItem = LocalStorageService.getStockItem(cloudItem.id);
        
        if (localItem == null) {
          // Item doesn't exist locally, add it
          await LocalStorageService.addStockItem(cloudItem);
        } else if (cloudItem.updatedAt.isAfter(localItem.updatedAt)) {
          // Cloud version is newer, update local
          await LocalStorageService.updateStockItem(cloudItem);
        }
      }

      // Fetch and sync movements
      final cloudMovements = await FirebaseService.fetchMovements();
      final localMovements = LocalStorageService.getAllMovements();
      for (final movement in cloudMovements) {
        if (!localMovements.any((m) => m.id == movement.id)) {
          await LocalStorageService.addMovement(movement);
        }
      }
    } catch (e) {
      throw Exception('Full sync failed: $e');
    }
  }

  // Push all unsynced local items to cloud
  Future<void> fullSyncToCloud() async {
    final unsyncedItems = LocalStorageService.getAllStockItems()
        .where((item) => !item.isSynced)
        .toList();

    for (final item in unsyncedItems) {
      final syncItem = SyncQueueItem(
        id: const Uuid().v4(),
        action: 'create',
        collection: 'stock_items',
        data: item.toMap(),
      );
      await LocalStorageService.addToSyncQueue(syncItem);
    }

    // Process the queue
    await processSyncQueue();
  }

  // Sync connection hours
  Future<void> syncConnectionHours(DateTime connectedAt, DateTime disconnectedAt) async {
    final activity = Activity(
      id: const Uuid().v4(),
      type: 'connection',
      title: 'Session',
      description: 'Connected: ${connectedAt.toString()}, Disconnected: ${disconnectedAt.toString()}',
      timestamp: connectedAt,
      metadata: {
        'connectedAt': connectedAt.toIso8601String(),
        'disconnectedAt': disconnectedAt.toIso8601String(),
        'duration': disconnectedAt.difference(connectedAt).inMinutes,
      },
    );

    await LocalStorageService.addActivity(activity);
    await queueForSync(
      action: 'create',
      collection: 'activities',
      data: activity.toMap(),
    );
  }

  // Auto sync when online
  Future<void> autoSync() async {
    if (await FirebaseService.checkConnection()) {
      await processSyncQueue();
      await fullSyncFromCloud();
    }
  }
}
