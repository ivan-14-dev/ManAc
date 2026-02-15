import 'package:uuid/uuid.dart';
import '../models/equipment_checkout.dart';
import '../models/activity.dart';
import 'local_storage_service.dart';
import 'sync_service.dart';
import 'firebase_service.dart';

/// Service responsible for managing equipment returns
/// Works even if checkout was made on another device
class ReturnService {
  static final ReturnService _instance = ReturnService._internal();
  factory ReturnService() => _instance;
  ReturnService._internal();

  final _uuid = const Uuid();

  /// Returns equipment using checkout ID (direct return)
  /// Works even if checkout was created on another device
  Future<EquipmentCheckout> returnByCheckoutId({
    required String checkoutId,
    required String userId,
    required String userName,
    String? notes,
  }) async {
    // First try to find in local storage
    var checkout = LocalStorageService.getCheckoutById(checkoutId);
    
    // If not found locally, try to fetch from Firebase
    if (checkout == null) {
      try {
        checkout = await FirebaseService.getCheckoutById(checkoutId);
        if (checkout != null) {
          // Save to local storage for offline access
          await LocalStorageService.addCheckout(checkout);
        }
      } catch (e) {
        // Firebase not available or error, continue with null
      }
    }
    
    if (checkout == null) {
      throw Exception('Checkout not found with ID: $checkoutId');
    }

    if (checkout.isReturned) {
      throw Exception('Equipment already returned');
    }

    return await _processReturn(
      checkout: checkout,
      userId: userId,
      userName: userName,
      notes: notes,
    );
  }

  /// Returns equipment by searching checkout (cross-device support)
  /// Searches by: borrower name, equipment name, room, and optionally quantity
  Future<EquipmentCheckout?> returnBySearch({
    required String borrowerName,
    required String equipmentName,
    required String destinationRoom,
    int? quantity,
    required String userId,
    required String userName,
    String? notes,
  }) async {
    // Find matching checkout
    final checkout = _findMatchingCheckout(
      borrowerName: borrowerName,
      equipmentName: equipmentName,
      destinationRoom: destinationRoom,
      quantity: quantity,
    );

    if (checkout == null) {
      return null;
    }

    return await _processReturn(
      checkout: checkout,
      userId: userId,
      userName: userName,
      notes: notes,
    );
  }

  /// Finds matching checkout for return
  EquipmentCheckout? _findMatchingCheckout({
    required String borrowerName,
    required String equipmentName,
    required String destinationRoom,
    int? quantity,
  }) {
    final activeCheckouts = LocalStorageService.getActiveCheckouts();
    
    // Filter by matching criteria
    final matches = activeCheckouts.where((checkout) {
      final nameMatch = _normalizeForComparison(checkout.equipmentName) == 
                       _normalizeForComparison(equipmentName);
      final borrowerMatch = _normalizeForComparison(checkout.borrowerName) == 
                           _normalizeForComparison(borrowerName);
      final roomMatch = _normalizeForComparison(checkout.destinationRoom) == 
                       _normalizeForComparison(destinationRoom);
      
      if (quantity != null) {
        return nameMatch && borrowerMatch && roomMatch && checkout.quantity == quantity;
      }
      
      return nameMatch && borrowerMatch && roomMatch;
    }).toList();

    // If multiple matches, return the oldest (first borrowed)
    if (matches.isEmpty) {
      return null;
    }
    
    matches.sort((a, b) => a.checkoutTime.compareTo(b.checkoutTime));
    return matches.first;
  }

  /// Normalizes string for comparison (case-insensitive, trims whitespace)
  String _normalizeForComparison(String value) {
    return value.toLowerCase().trim();
  }

  /// Processes the return operation
  Future<EquipmentCheckout> _processReturn({
    required EquipmentCheckout checkout,
    required String userId,
    required String userName,
    String? notes,
  }) async {
    final now = DateTime.now();
    
    // Update checkout with return info
    final updatedCheckout = checkout.copyWith(
      returnTime: now,
      isReturned: true,
      notes: notes ?? checkout.notes,
      isSynced: false,
    );

    // Save locally
    await LocalStorageService.updateCheckout(updatedCheckout);

    // Queue for synchronization
    await SyncService.queueForSync(
      action: 'update',
      collection: 'equipment_checkouts',
      data: updatedCheckout.toMap(),
    );

    // Create activity log
    await _createReturnActivity(updatedCheckout, userId, userName);

    return updatedCheckout;
  }

  /// Creates activity log for return
  Future<void> _createReturnActivity(
    EquipmentCheckout checkout,
    String userId,
    String userName,
  ) async {
    final duration = checkout.returnTime != null 
        ? checkout.returnTime!.difference(checkout.checkoutTime)
        : Duration.zero;

    final activity = Activity(
      id: _uuid.v4(),
      type: 'return',
      title: 'Retour d\'équipement',
      description: 'Retour de ${checkout.quantity} ${checkout.equipmentName} par ${checkout.borrowerName} de la salle ${checkout.destinationRoom}. Durée: ${duration.inHours}h ${duration.inMinutes % 60}min',
      userId: userId,
      userName: userName,
      metadata: {
        'checkoutId': checkout.id,
        'equipmentId': checkout.equipmentId,
        'equipmentName': checkout.equipmentName,
        'borrowerName': checkout.borrowerName,
        'destinationRoom': checkout.destinationRoom,
        'quantity': checkout.quantity,
        'checkoutTime': checkout.checkoutTime.toIso8601String(),
        'returnTime': checkout.returnTime?.toIso8601String(),
        'duration': duration.inMinutes,
        'action': 'return',
      },
    );

    await LocalStorageService.addActivity(activity);
    await SyncService.queueForSync(
      action: 'create',
      collection: 'activities',
      data: activity.toMap(),
    );
  }

  /// Gets all returned checkouts
  List<EquipmentCheckout> getReturnedCheckouts() {
    return LocalStorageService.getReturnedCheckouts();
  }

  /// Gets return history for an equipment
  List<EquipmentCheckout> getReturnHistory(String equipmentId) {
    return LocalStorageService.getCheckoutsByEquipment(equipmentId)
        .where((c) => c.isReturned)
        .toList()
      ..sort((a, b) => (b.returnTime ?? DateTime.now()).compareTo(a.returnTime ?? DateTime.now()));
  }

  /// Searches returns by multiple criteria
  List<EquipmentCheckout> searchReturns({
    String? borrowerName,
    String? equipmentName,
    String? room,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    var checkouts = LocalStorageService.getAllCheckouts().where((c) => c.isReturned).toList();

    if (borrowerName != null && borrowerName.isNotEmpty) {
      checkouts = checkouts
          .where((c) => c.borrowerName.toLowerCase().contains(borrowerName.toLowerCase()))
          .toList();
    }

    if (equipmentName != null && equipmentName.isNotEmpty) {
      checkouts = checkouts
          .where((c) => c.equipmentName.toLowerCase().contains(equipmentName.toLowerCase()))
          .toList();
    }

    if (room != null && room.isNotEmpty) {
      checkouts = checkouts
          .where((c) => c.destinationRoom.toLowerCase().contains(room.toLowerCase()))
          .toList();
    }

    if (fromDate != null) {
      checkouts = checkouts
          .where((c) => c.returnTime != null && c.returnTime!.isAfter(fromDate))
          .toList();
    }

    if (toDate != null) {
      checkouts = checkouts
          .where((c) => c.returnTime != null && c.returnTime!.isBefore(toDate))
          .toList();
    }

    return checkouts..sort((a, b) => (b.returnTime ?? DateTime.now()).compareTo(a.returnTime ?? DateTime.now()));
  }

  /// Gets return statistics
  Map<String, dynamic> getReturnStats() {
    final returnedCheckouts = LocalStorageService.getReturnedCheckouts();
    
    // Calculate average return duration
    int totalMinutes = 0;
    int countWithDuration = 0;
    
    for (final checkout in returnedCheckouts) {
      if (checkout.returnTime != null) {
        totalMinutes += checkout.returnTime!.difference(checkout.checkoutTime).inMinutes;
        countWithDuration++;
      }
    }
    
    final avgDuration = countWithDuration > 0 ? totalMinutes ~/ countWithDuration : 0;

    return {
      'totalReturns': returnedCheckouts.length,
      'averageReturnDurationMinutes': avgDuration,
      'averageReturnDuration': '${avgDuration ~/ 60}h ${avgDuration % 60}min',
      'pendingSync': returnedCheckouts.where((c) => !c.isSynced).length,
    };
  }

  /// Gets overdue checkouts (active checkouts older than specified days)
  List<EquipmentCheckout> getOverdueCheckouts({int overdueDays = 7}) {
    final activeCheckouts = LocalStorageService.getActiveCheckouts();
    final cutoffDate = DateTime.now().subtract(Duration(days: overdueDays));
    
    return activeCheckouts
        .where((c) => c.checkoutTime.isBefore(cutoffDate))
        .toList()
      ..sort((a, b) => a.checkoutTime.compareTo(b.checkoutTime));
  }

  /// Validates if a return can be processed (for preview before confirming)
  ReturnValidationResult validateReturn({
    required String borrowerName,
    required String equipmentName,
    required String destinationRoom,
    int? quantity,
  }) {
    final matchingCheckout = _findMatchingCheckout(
      borrowerName: borrowerName,
      equipmentName: equipmentName,
      destinationRoom: destinationRoom,
      quantity: quantity,
    );

    if (matchingCheckout == null) {
      return ReturnValidationResult(
        isValid: false,
        message: 'Aucun emprunt trouvé correspondant aux critères',
        checkout: null,
      );
    }

    if (matchingCheckout.isReturned) {
      return ReturnValidationResult(
        isValid: false,
        message: 'Cet équipement a déjà été retourné',
        checkout: matchingCheckout,
      );
    }

    final daysSinceCheckout = DateTime.now().difference(matchingCheckout.checkoutTime).inDays;
    
    return ReturnValidationResult(
      isValid: true,
      message: 'Emprunt trouvé - ${daysSinceCheckout} jour(s) depuis l\'emprunt',
      checkout: matchingCheckout,
    );
  }
}

/// Result of return validation
class ReturnValidationResult {
  final bool isValid;
  final String message;
  final EquipmentCheckout? checkout;

  ReturnValidationResult({
    required this.isValid,
    required this.message,
    this.checkout,
  });
}
