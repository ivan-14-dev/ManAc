import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/stock_item.dart';
import '../models/stock_movement.dart';
import '../models/sync_queue_item.dart';
import '../models/activity.dart';

class LocalStorageService {
  static late SharedPreferences _prefs;
  static const String _stockBox = 'stock_items';
  static const String _movementsBox = 'stock_movements';
  static const String _syncQueueBox = 'sync_queue';
  static const String _activitiesBox = 'activities';

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Stock Items
  static Future<void> addStockItem(StockItem item) async {
    final items = getAllStockItems();
    items.add(item);
    await _saveStockItems(items);
  }
  
  static Future<void> updateStockItem(StockItem item) async {
    final items = getAllStockItems();
    final index = items.indexWhere((e) => e.id == item.id);
    if (index >= 0) {
      items[index] = item.copyWith(updatedAt: DateTime.now(), isSynced: false);
      await _saveStockItems(items);
    }
  }
  
  static Future<void> deleteStockItem(String id) async {
    final items = getAllStockItems();
    items.removeWhere((e) => e.id == id);
    await _saveStockItems(items);
  }
  
  static StockItem? getStockItem(String id) {
    try {
      return getAllStockItems().firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }
  
  static List<StockItem> getAllStockItems() {
    final jsonString = _prefs.getString(_stockBox);
    if (jsonString == null || jsonString.isEmpty) return [];
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((e) => StockItem.fromMap(e)).toList();
  }
  
  static Future<void> _saveStockItems(List<StockItem> items) async {
    final jsonList = items.map((e) => e.toMap()).toList();
    await _prefs.setString(_stockBox, json.encode(jsonList));
  }
  
  static List<StockItem> getLowStockItems() {
    return getAllStockItems().where((item) => item.isLowStock).toList();
  }
  
  static List<StockItem> searchStockItems(String query) {
    final lowercaseQuery = query.toLowerCase();
    return getAllStockItems()
        .where((item) =>
            item.name.toLowerCase().contains(lowercaseQuery) ||
            item.category.toLowerCase().contains(lowercaseQuery) ||
            (item.barcode?.toLowerCase().contains(lowercaseQuery) ?? false))
        .toList();
  }

  // Stock Movements
  static Future<void> addMovement(StockMovement movement) async {
    final movements = getAllMovements();
    movements.add(movement);
    await _saveMovements(movements);
  }
  
  static List<StockMovement> getAllMovements() {
    final jsonString = _prefs.getString(_movementsBox);
    if (jsonString == null || jsonString.isEmpty) return [];
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((e) => StockMovement.fromMap(e)).toList();
  }
  
  static List<StockMovement> getMovementsByItem(String stockItemId) {
    return getAllMovements()
        .where((m) => m.stockItemId == stockItemId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }
  
  static List<StockMovement> getRecentMovements({int limit = 50}) {
    return getAllMovements()
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date))
      ..take(limit);
  }

  static Future<void> _saveMovements(List<StockMovement> movements) async {
    final jsonList = movements.map((e) => e.toMap()).toList();
    await _prefs.setString(_movementsBox, json.encode(jsonList));
  }

  // Sync Queue
  static Future<void> addToSyncQueue(SyncQueueItem item) async {
    final items = getSyncQueue();
    items.add(item);
    await _saveSyncQueue(items);
  }
  
  static Future<void> removeFromSyncQueue(String id) async {
    final items = getSyncQueue();
    items.removeWhere((e) => e.id == id);
    await _saveSyncQueue(items);
  }
  
  static List<SyncQueueItem> getSyncQueue() {
    final jsonString = _prefs.getString(_syncQueueBox);
    if (jsonString == null || jsonString.isEmpty) return [];
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((e) => SyncQueueItem.fromMap(e)).toList();
  }
  
  static List<SyncQueueItem> getPendingSyncItems() {
    return getSyncQueue().where((item) => item.retryCount < 3).toList();
  }
  
  static Future<void> updateSyncItem(SyncQueueItem item) async {
    final items = getSyncQueue();
    final index = items.indexWhere((e) => e.id == item.id);
    if (index >= 0) {
      items[index] = item;
      await _saveSyncQueue(items);
    }
  }

  static Future<void> _saveSyncQueue(List<SyncQueueItem> items) async {
    final jsonList = items.map((e) => e.toMap()).toList();
    await _prefs.setString(_syncQueueBox, json.encode(jsonList));
  }

  // Activities
  static Future<void> addActivity(Activity activity) async {
    final activities = getAllActivities();
    activities.add(activity);
    await _saveActivities(activities);
  }
  
  static List<Activity> getAllActivities() {
    final jsonString = _prefs.getString(_activitiesBox);
    if (jsonString == null || jsonString.isEmpty) return [];
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((e) => Activity.fromMap(e)).toList();
  }
  
  static List<Activity> getRecentActivities({int limit = 100}) {
    return getAllActivities()
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp))
      ..take(limit);
  }
  
  static List<Activity> getUnsyncedActivities() {
    return getAllActivities().where((a) => !a.isSynced).toList();
  }

  static Future<void> _saveActivities(List<Activity> activities) async {
    final jsonList = activities.map((e) => e.toMap()).toList();
    await _prefs.setString(_activitiesBox, json.encode(jsonList));
  }

  // Settings
  static Future<void> setSetting(String key, dynamic value) async {
    if (value is bool) {
      await _prefs.setBool(key, value);
    } else if (value is int) {
      await _prefs.setInt(key, value);
    } else if (value is double) {
      await _prefs.setDouble(key, value);
    } else if (value is String) {
      await _prefs.setString(key, value);
    } else {
      await _prefs.setString(key, json.encode(value));
    }
  }
  
  static dynamic getSetting(String key, {dynamic defaultValue}) {
    return _prefs.get(key) ?? defaultValue;
  }

  // Sync status
  static Future<void> markItemAsSynced(String id, String firebaseId) async {
    final items = getAllStockItems();
    final index = items.indexWhere((e) => e.id == id);
    if (index >= 0) {
      items[index] = items[index].copyWith(isSynced: true, firebaseId: firebaseId);
      await _saveStockItems(items);
    }
  }
  
  static Future<void> markMovementAsSynced(String id) async {
    final movements = getAllMovements();
    final index = movements.indexWhere((e) => e.id == id);
    if (index >= 0) {
      movements[index] = movements[index].copyWith(isSynced: true);
      await _saveMovements(movements);
    }
  }

  // Clear all data
  static Future<void> clearAllData() async {
    await _prefs.remove(_stockBox);
    await _prefs.remove(_movementsBox);
    await _prefs.remove(_syncQueueBox);
    await _prefs.remove(_activitiesBox);
    await _prefs.clear();
  }
}
