import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/stock_item.dart';
import '../models/stock_movement.dart';
import '../models/activity.dart';
import '../services/local_storage_service.dart';
import '../services/sync_service.dart';

class StockProvider with ChangeNotifier {
  List<StockItem> _stockItems = [];
  List<StockItem> _filteredItems = [];
  List<StockMovement> _recentMovements = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _sortBy = 'name';

  List<StockItem> get stockItems => _stockItems;
  List<StockItem> get filteredItems => _filteredItems;
  List<StockMovement> get recentMovements => _recentMovements;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;

  List<String> get categories {
    final cats = {'All', ..._stockItems.map((e) => e.category)};
    return cats.toList()..sort();
  }

  int get totalItems => _stockItems.length;
  int get totalQuantity => _stockItems.fold(0, (sum, item) => sum + item.quantity);
  int get lowStockCount => _stockItems.where((e) => e.isLowStock).length;
  double get totalValue => _stockItems.fold(0, (sum, item) => sum + (item.price * item.quantity));

  StockProvider() {
    loadData();
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    _stockItems = LocalStorageService.getAllStockItems();
    _recentMovements = LocalStorageService.getRecentMovements(limit: 20);
    
    _applyFilters();
    _isLoading = false;
    notifyListeners();
  }

  void _applyFilters() {
    _filteredItems = _stockItems.where((item) {
      final matchesSearch = _searchQuery.isEmpty ||
          item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (item.barcode?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      
      final matchesCategory = _selectedCategory == 'All' || item.category == _selectedCategory;
      
      return matchesSearch && matchesCategory;
    }).toList();

    _sortItems();
  }

  void _sortItems() {
    switch (_sortBy) {
      case 'name':
        _filteredItems.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'quantity':
        _filteredItems.sort((a, b) => a.quantity.compareTo(b.quantity));
        break;
      case 'price':
        _filteredItems.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'category':
        _filteredItems.sort((a, b) => a.category.compareTo(b.category));
        break;
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  void setSortBy(String sortBy) {
    _sortBy = sortBy;
    _applyFilters();
    notifyListeners();
  }

  Future<void> addStockItem({
    required String name,
    required String category,
    required int quantity,
    required int minQuantity,
    required String unit,
    required double price,
    String? description,
    String? barcode,
    String location = 'Main Warehouse',
  }) async {
    final item = StockItem(
      id: const Uuid().v4(),
      name: name,
      category: category,
      quantity: quantity,
      minQuantity: minQuantity,
      unit: unit,
      price: price,
      description: description,
      barcode: barcode,
      location: location,
    );

    await LocalStorageService.addStockItem(item);
    
    // Add activity
    await _addActivity(
      type: 'stock_in',
      title: 'New Item Added',
      description: 'Added $name ($quantity $unit)',
      metadata: {'itemId': item.id, 'quantity': quantity},
    );

    // Queue for sync
    await SyncService.queueForSync(
      action: 'create',
      collection: 'stock_items',
      data: item.toMap(),
    );

    await loadData();
  }

  Future<void> updateStockItem(StockItem item) async {
    await LocalStorageService.updateStockItem(item);

    // Add activity
    await _addActivity(
      type: 'stock_adjustment',
      title: 'Item Updated',
      description: 'Updated ${item.name}',
      metadata: {'itemId': item.id},
    );

    // Queue for sync
    await SyncService.queueForSync(
      action: 'update',
      collection: 'stock_items',
      data: item.toMap(),
    );

    await loadData();
  }

  Future<void> deleteStockItem(String id) async {
    final item = LocalStorageService.getStockItem(id);
    if (item != null) {
      await LocalStorageService.deleteStockItem(id);

      // Add activity
      await _addActivity(
        type: 'stock_out',
        title: 'Item Deleted',
        description: 'Deleted ${item.name}',
        metadata: {'itemId': id},
      );

      // Queue for sync
      await SyncService.queueForSync(
        action: 'delete',
        collection: 'stock_items',
        data: item.toMap(),
      );
    }

    await loadData();
  }

  Future<void> adjustStock({
    required String stockItemId,
    required int adjustment,
    required String type,
    String? reason,
    String? reference,
  }) async {
    final item = LocalStorageService.getStockItem(stockItemId);
    if (item == null) return;

    final newQuantity = type == 'in' 
        ? item.quantity + adjustment 
        : item.quantity - adjustment;

    if (newQuantity < 0) return;

    final updatedItem = item.copyWith(quantity: newQuantity);
    await LocalStorageService.updateStockItem(updatedItem);

    // Record movement
    final movement = StockMovement(
      id: const Uuid().v4(),
      stockItemId: stockItemId,
      type: type,
      quantity: adjustment,
      reason: reason,
      reference: reference,
    );
    await LocalStorageService.addMovement(movement);

    // Add activity
    await _addActivity(
      type: type == 'in' ? 'stock_in' : 'stock_out',
      title: 'Stock ${type == 'in' ? 'Added' : 'Removed'}',
      description: '${type == 'in' ? 'Added' : 'Removed'} $adjustment ${item.unit} of ${item.name}',
      metadata: {
        'itemId': stockItemId,
        'adjustment': adjustment,
        'newQuantity': newQuantity,
        'type': type,
      },
    );

    // Queue for sync
    await SyncService.queueForSync(
      action: 'create',
      collection: 'stock_movements',
      data: movement.toMap(),
    );

    await loadData();
  }

  Future<void> _addActivity({
    required String type,
    required String title,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    final activity = Activity(
      id: const Uuid().v4(),
      type: type,
      title: title,
      description: description,
      metadata: metadata,
    );
    await LocalStorageService.addActivity(activity);
  }

  List<StockItem> searchItems(String query) {
    return LocalStorageService.searchStockItems(query);
  }

  List<StockItem> getLowStockItems() {
    return LocalStorageService.getLowStockItems();
  }

  StockItem? getItemById(String id) {
    return LocalStorageService.getStockItem(id);
  }
}
