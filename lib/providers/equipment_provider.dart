// ========================================
// Provider d'équipements
// Gère les équipements, les emprunts et les rapports quotidiens
// ========================================

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/equipment.dart';
import '../models/equipment_checkout.dart';
import '../models/daily_report.dart';
import '../models/activity.dart';
import '../services/local_storage_service.dart';
import '../services/sync_service.dart';

// Provider d'équipements avec ChangeNotifier
class EquipmentProvider with ChangeNotifier {
  List<Equipment> _equipment = [];
  List<Equipment> _filteredEquipment = [];
  List<EquipmentCheckout> _activeCheckouts = [];
  List<EquipmentCheckout> _allCheckouts = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedCategory = 'All';

  // Getters
  List<Equipment> get equipment => _equipment;
  List<Equipment> get filteredEquipment => _filteredEquipment;
  List<EquipmentCheckout> get activeCheckouts => _activeCheckouts;
  List<EquipmentCheckout> get allCheckouts => _allCheckouts;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;

  List<String> get categories {
    final cats = {'All', ..._equipment.map((e) => e.category)};
    return cats.toList()..sort();
  }

  int get totalEquipment => _equipment.length;
  int get availableEquipment => _equipment.where((e) => e.isAvailable).length;
  int get checkedOutEquipment => _activeCheckouts.length;

  EquipmentProvider() {
    loadData();
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    _equipment = LocalStorageService.getAllEquipment();
    _allCheckouts = LocalStorageService.getAllCheckouts();
    _activeCheckouts = LocalStorageService.getActiveCheckouts();
    
    _applyFilters();
    _isLoading = false;
    notifyListeners();
  }

  void _applyFilters() {
    _filteredEquipment = _equipment.where((item) {
      final matchesSearch = _searchQuery.isEmpty ||
          item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.serialNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (item.barcode?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      
      final matchesCategory = _selectedCategory == 'All' || item.category == _selectedCategory;
      
      return matchesSearch && matchesCategory;
    }).toList();

    _filteredEquipment.sort((a, b) => a.name.compareTo(b.name));
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

  // Equipment CRUD Operations
  Future<void> addEquipment({
    required String name,
    required String category,
    required String description,
    required String serialNumber,
    String? barcode,
    required String location,
    required int quantity,
    double value = 0,
    String? photoPath,
    String userId = 'system',
    String userName = 'System',
  }) async {
    final eq = Equipment(
      id: Equipment.generateId(),
      name: name,
      category: category,
      description: description,
      serialNumber: serialNumber,
      barcode: barcode,
      location: location,
      status: 'available',
      totalQuantity: quantity,
      availableQuantity: quantity,
      photoPath: photoPath,
      value: value,
      purchaseDate: DateTime.now(),
      userId: userId,
      userName: userName,
    );

    await LocalStorageService.addEquipment(eq);
    
    await _addActivity(
      type: 'equipment_added',
      title: 'Equipment Added',
      description: 'Added $name (Qty: $quantity)',
      metadata: {'equipmentId': eq.id, 'quantity': quantity},
    );

    await SyncService.queueForSync(
      action: 'create',
      collection: 'equipment',
      data: eq.toMap(),
    );

    await loadData();
  }

  Future<void> updateEquipment(Equipment equipment) async {
    await LocalStorageService.updateEquipment(equipment);
    
    await _addActivity(
      type: 'equipment_updated',
      title: 'Equipment Updated',
      description: 'Updated ${equipment.name}',
      metadata: {'equipmentId': equipment.id},
    );

    await SyncService.queueForSync(
      action: 'update',
      collection: 'equipment',
      data: equipment.toMap(),
    );

    await loadData();
  }

  Future<void> deleteEquipment(String id) async {
    final eq = LocalStorageService.getEquipment(id);
    if (eq != null) {
      await LocalStorageService.deleteEquipment(id);

      await _addActivity(
        type: 'equipment_deleted',
        title: 'Equipment Deleted',
        description: 'Deleted ${eq.name}',
        metadata: {'equipmentId': id},
      );

      await SyncService.queueForSync(
        action: 'delete',
        collection: 'equipment',
        data: eq.toMap(),
      );
    }

    await loadData();
  }

  // Checkout Operations
  Future<EquipmentCheckout> checkoutEquipment({
    required String equipmentId,
    required String borrowerName,
    required String borrowerCni,
    required String borrowerEmail,
    required String cniPhotoPath,
    required String destinationRoom,
    required int quantity,
    String? equipmentPhotoPath,
    String? notes,
    String userId = 'system',
    String userName = 'System',
  }) async {
    final equipment = LocalStorageService.getEquipment(equipmentId);
    if (equipment == null) {
      throw Exception('Equipment not found');
    }

    if (equipment.availableQuantity < quantity) {
      throw Exception('Insufficient quantity available');
    }

    final checkout = EquipmentCheckout(
      id: EquipmentCheckout.generateId(),
      equipmentId: equipmentId,
      equipmentName: equipment.name,
      equipmentPhotoPath: equipmentPhotoPath ?? equipment.photoPath ?? '',
      borrowerName: borrowerName,
      borrowerCni: borrowerCni,
      borrowerEmail: borrowerEmail,
      cniPhotoPath: cniPhotoPath,
      destinationRoom: destinationRoom,
      quantity: quantity,
      checkoutTime: DateTime.now(),
      isReturned: false,
      notes: notes,
      userId: userId,
      userName: userName,
    );

    // Update equipment available quantity
    final updatedEquipment = equipment.copyWith(
      availableQuantity: equipment.availableQuantity - quantity,
      status: equipment.availableQuantity - quantity == 0 ? 'checked_out' : 'available',
    );
    await LocalStorageService.updateEquipment(updatedEquipment);

    // Save checkout
    await LocalStorageService.addCheckout(checkout);

    // Add activity
    await _addActivity(
      type: 'checkout',
      title: 'Equipment Checked Out',
      description: '$quantity x ${equipment.name} to $borrowerName',
      metadata: {
        'checkoutId': checkout.id,
        'equipmentId': equipmentId,
        'quantity': quantity,
        'borrowerName': borrowerName,
        'destinationRoom': destinationRoom,
      },
    );

    // Queue for sync
    await SyncService.queueForSync(
      action: 'create',
      collection: 'equipment_checkouts',
      data: checkout.toMap(),
    );

    await SyncService.queueForSync(
      action: 'update',
      collection: 'equipment',
      data: updatedEquipment.toMap(),
    );

    await loadData();
    return checkout;
  }

  Future<void> returnEquipment({
    required String checkoutId,
    String userId = 'system',
    String userName = 'System',
  }) async {
    final checkout = LocalStorageService.getCheckoutById(checkoutId);
    if (checkout == null) {
      throw Exception('Checkout not found');
    }

    if (checkout.isReturned) {
      throw Exception('Equipment already returned');
    }

    // Update checkout
    final updatedCheckout = checkout.copyWith(
      returnTime: DateTime.now(),
      isReturned: true,
      userId: userId,
      userName: userName,
    );
    await LocalStorageService.updateCheckout(updatedCheckout);

    // Update equipment available quantity
    final equipment = LocalStorageService.getEquipment(checkout.equipmentId);
    if (equipment != null) {
      final updatedEquipment = equipment.copyWith(
        availableQuantity: equipment.availableQuantity + checkout.quantity,
        status: 'available',
      );
      await LocalStorageService.updateEquipment(updatedEquipment);

      await SyncService.queueForSync(
        action: 'update',
        collection: 'equipment',
        data: updatedEquipment.toMap(),
      );
    }

    // Add activity
    await _addActivity(
      type: 'return',
      title: 'Equipment Returned',
      description: '${checkout.equipmentName} returned by ${checkout.borrowerName}',
      metadata: {
        'checkoutId': checkoutId,
        'equipmentId': checkout.equipmentId,
        'quantity': checkout.quantity,
      },
    );

    // Queue checkout for sync
    await SyncService.queueForSync(
      action: 'update',
      collection: 'equipment_checkouts',
      data: updatedCheckout.toMap(),
    );

    await loadData();
  }

  // Daily Report Generation
  Future<DailyReport> generateDailyReport({
    String userId = 'system',
    String userName = 'System',
  }) async {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    // Get today's checkouts
    final todayCheckouts = _allCheckouts
        .where((e) => 
            e.checkoutTime.isAfter(todayStart) && 
            e.checkoutTime.isBefore(todayEnd))
        .toList();

    // Get today's returns
    final todayReturns = todayCheckouts
        .where((e) => e.isReturned && e.returnTime != null)
        .toList();

    final totalCheckouts = todayCheckouts.length;
    final totalReturns = todayReturns.length;
    final totalItemsCheckedOut = todayCheckouts.fold(0, (sum, e) => sum + e.quantity);
    final totalItemsReturned = todayReturns.fold(0, (sum, e) => sum + e.quantity);

    // Generate summary
    final summary = _generateReportSummary(
      totalCheckouts,
      totalReturns,
      totalItemsCheckedOut,
      totalItemsReturned,
      todayCheckouts,
      todayReturns,
    );

    final report = DailyReport(
      id: Equipment.generateId(),
      date: todayStart,
      totalCheckouts: totalCheckouts,
      totalReturns: totalReturns,
      totalItemsCheckedOut: totalItemsCheckedOut,
      totalItemsReturned: totalItemsReturned,
      checkoutIds: todayCheckouts.map((e) => e.id).toList(),
      returnIds: todayReturns.map((e) => e.id).toList(),
      summary: summary,
      generatedBy: userName,
      generatedAt: DateTime.now(),
    );

    await LocalStorageService.addDailyReport(report);

    await _addActivity(
      type: 'daily_report',
      title: 'Daily Report Generated',
      description: 'Report for ${today.day}/${today.month}/${today.year}: $totalCheckouts checkouts, $totalReturns returns',
      metadata: {'reportId': report.id},
    );

    await SyncService.queueForSync(
      action: 'create',
      collection: 'daily_reports',
      data: report.toMap(),
    );

    await loadData();
    return report;
  }

  String _generateReportSummary(
    int totalCheckouts,
    int totalReturns,
    int totalItemsCheckedOut,
    int totalItemsReturned,
    List<EquipmentCheckout> checkouts,
    List<EquipmentCheckout> returns,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('=== DAILY EQUIPMENT REPORT ===');
    buffer.writeln('Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}');
    buffer.writeln('');
    buffer.writeln('SUMMARY:');
    buffer.writeln('- Total Checkouts: $totalCheckouts');
    buffer.writeln('- Total Returns: $totalReturns');
    buffer.writeln('- Items Checked Out: $totalItemsCheckedOut');
    buffer.writeln('- Items Returned: $totalItemsReturned');
    buffer.writeln('');
    
    if (checkouts.isNotEmpty) {
      buffer.writeln('CHECKOUT DETAILS:');
      for (final checkout in checkouts) {
        buffer.writeln('- ${checkout.equipmentName} (${checkout.quantity}x) -> ${checkout.borrowerName} (Room: ${checkout.destinationRoom}) at ${checkout.checkoutTime.hour}:${checkout.checkoutTime.minute.toString().padLeft(2, '0')}');
      }
      buffer.writeln('');
    }

    if (returns.isNotEmpty) {
      buffer.writeln('RETURN DETAILS:');
      for (final ret in returns) {
        buffer.writeln('- ${ret.equipmentName} (${ret.quantity}x) returned by ${ret.borrowerName} at ${ret.returnTime!.hour}:${ret.returnTime!.minute.toString().padLeft(2, '0')}');
      }
    }

    return buffer.toString();
  }

  Future<DailyReport?> getTodayReport() async {
    final today = DateTime.now();
    return LocalStorageService.getDailyReportByDate(today);
  }

  List<DailyReport> getMonthlyReports(int year, int month) {
    return LocalStorageService.getDailyReportsByMonth(year, month);
  }

  // Helper method to add activity
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

  // Search methods
  List<Equipment> searchEquipment(String query) {
    return LocalStorageService.searchEquipment(query);
  }

  Equipment? getEquipmentById(String id) {
    return LocalStorageService.getEquipment(id);
  }

  EquipmentCheckout? getCheckoutById(String id) {
    return LocalStorageService.getCheckoutById(id);
  }
}
