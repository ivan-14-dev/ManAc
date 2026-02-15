import 'package:uuid/uuid.dart';
import '../models/equipment_checkout.dart';
import '../models/activity.dart';
import 'local_storage_service.dart';
import 'sync_service.dart';

/// Service responsible for managing equipment checkouts (borrowing)
/// This class handles the borrowing process and ensures proper synchronization
class CheckoutService {
  static final CheckoutService _instance = CheckoutService._internal();
  factory CheckoutService() => _instance;
  CheckoutService._internal();

  final _uuid = const Uuid();

  /// Generates a meaningful checkout ID based on:
  /// - Year (2 digits)
  /// - Time (HHMMSS)
  /// - User name initials (first letter of first and last name)
  /// - Room code (first 3 letters, uppercase)
  /// Format: YYHHMMSS-US-Room
  String _generateCheckoutId({
    required String userName,
    required String destinationRoom,
  }) {
    final now = DateTime.now();
    
    // Year (2 digits)
    final year = now.year.toString().substring(2);
    
    // Time (HHMMSS)
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final second = now.second.toString().padLeft(2, '0');
    final timeStr = '$hour$minute$second';
    
    // User name initials (first letter of first and last name)
    final userInitials = _getInitials(userName);
    
    // Room code (first 3 letters, uppercase, remove spaces)
    final roomCode = _getRoomCode(destinationRoom);
    
    // Unique suffix using UUID short form
    final uniqueSuffix = _uuid.v4().substring(0, 4).toUpperCase();
    
    return '$year$timeStr-$userInitials-$roomCode-$uniqueSuffix';
  }

  /// Extracts initials from user name
  String _getInitials(String userName) {
    final parts = userName.trim().split(' ');
    if (parts.isEmpty) return 'XX';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length.clamp(0, 2)).toUpperCase();
    }
    // Take first letter of first two parts
    final first = parts[0].isNotEmpty ? parts[0][0] : '';
    final second = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
    return '$first$second'.toUpperCase();
  }

  /// Creates room code from destination room
  String _getRoomCode(String destinationRoom) {
    // Remove spaces and special characters, take first 3 letters
    final clean = destinationRoom.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    if (clean.length < 3) return clean.toUpperCase().padRight(3, 'X');
    return clean.substring(0, 3).toUpperCase();
  }

  /// Creates a new equipment checkout/borrow record
  /// Returns the created checkout record
  Future<EquipmentCheckout> createCheckout({
    required String equipmentId,
    required String equipmentName,
    required String equipmentPhotoPath,
    required String borrowerName,
    required String borrowerCni,
    required String cniPhotoPath,
    required String destinationRoom,
    required int quantity,
    required String userId,
    required String userName,
    String? notes,
  }) async {
    // Generate meaningful checkout ID based on year, time, user, room
    final checkoutId = _generateCheckoutId(
      userName: userName,
      destinationRoom: destinationRoom,
    );

    final checkout = EquipmentCheckout(
      id: checkoutId,
      equipmentId: equipmentId,
      equipmentName: equipmentName,
      equipmentPhotoPath: equipmentPhotoPath,
      borrowerName: borrowerName,
      borrowerCni: borrowerCni,
      cniPhotoPath: cniPhotoPath,
      destinationRoom: destinationRoom,
      quantity: quantity,
      checkoutTime: DateTime.now(),
      userId: userId,
      userName: userName,
      notes: notes,
      isSynced: false,
    );

    // Save locally
    await LocalStorageService.addCheckout(checkout);

    // Queue for synchronization
    await SyncService.queueForSync(
      action: 'create',
      collection: 'equipment_checkouts',
      data: checkout.toMap(),
    );

    // Create activity log
    await _createCheckoutActivity(checkout, userId, userName);

    return checkout;
  }

  /// Finds checkout by equipment ID and borrower name for cross-device returns
  /// This allows returns to work even if checkout was on another device
  EquipmentCheckout? findCheckoutForReturn({
    required String equipmentName,
    required String borrowerName,
    required String destinationRoom,
    int? quantity,
  }) {
    final activeCheckouts = LocalStorageService.getActiveCheckouts();
    
    // Try to find matching checkout by name, borrower, room, and optionally quantity
    return activeCheckouts.where((checkout) {
      final nameMatch = checkout.equipmentName.toLowerCase() == equipmentName.toLowerCase();
      final borrowerMatch = checkout.borrowerName.toLowerCase() == borrowerName.toLowerCase();
      final roomMatch = checkout.destinationRoom.toLowerCase() == destinationRoom.toLowerCase();
      
      // If quantity specified, also check quantity
      if (quantity != null) {
        return nameMatch && borrowerMatch && roomMatch && checkout.quantity == quantity;
      }
      
      return nameMatch && borrowerMatch && roomMatch;
    }).firstOrNull;
  }

  /// Finds checkout by ID - for direct return using checkout ID
  EquipmentCheckout? getCheckoutById(String checkoutId) {
    return LocalStorageService.getCheckoutById(checkoutId);
  }

  /// Gets all active (non-returned) checkouts
  List<EquipmentCheckout> getActiveCheckouts() {
    return LocalStorageService.getActiveCheckouts();
  }

  /// Gets all checkouts for a specific equipment
  List<EquipmentCheckout> getCheckoutsByEquipment(String equipmentId) {
    return LocalStorageService.getCheckoutsByEquipment(equipmentId);
  }

  /// Gets all checkouts by date range
  List<EquipmentCheckout> getCheckoutsByDateRange(DateTime start, DateTime end) {
    return LocalStorageService.getCheckoutsByDateRange(start, end);
  }

  /// Gets checkout history for a borrower
  List<EquipmentCheckout> getBorrowerHistory(String borrowerName) {
    return LocalStorageService.getAllCheckouts()
        .where((c) => c.borrowerName.toLowerCase() == borrowerName.toLowerCase())
        .toList()
      ..sort((a, b) => b.checkoutTime.compareTo(a.checkoutTime));
  }

  /// Searches checkouts by multiple criteria
  List<EquipmentCheckout> searchCheckouts({
    String? borrowerName,
    String? equipmentName,
    String? room,
    DateTime? fromDate,
    DateTime? toDate,
    bool? isReturned,
  }) {
    var checkouts = LocalStorageService.getAllCheckouts();

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
      checkouts = checkouts.where((c) => c.checkoutTime.isAfter(fromDate)).toList();
    }

    if (toDate != null) {
      checkouts = checkouts.where((c) => c.checkoutTime.isBefore(toDate)).toList();
    }

    if (isReturned != null) {
      checkouts = checkouts.where((c) => c.isReturned == isReturned).toList();
    }

    return checkouts..sort((a, b) => b.checkoutTime.compareTo(a.checkoutTime));
  }

  /// Creates activity log for checkout
  Future<void> _createCheckoutActivity(
    EquipmentCheckout checkout,
    String userId,
    String userName,
  ) async {
    final activity = Activity(
      id: _uuid.v4(),
      type: 'checkout',
      title: 'Emprunt d\'équipement',
      description: 'Emprunt de ${checkout.quantity} ${checkout.equipmentName} par ${checkout.borrowerName} pour la salle ${checkout.destinationRoom}',
      userId: userId,
      userName: userName,
      metadata: {
        'checkoutId': checkout.id,
        'equipmentId': checkout.equipmentId,
        'equipmentName': checkout.equipmentName,
        'borrowerName': checkout.borrowerName,
        'destinationRoom': checkout.destinationRoom,
        'quantity': checkout.quantity,
        'action': 'checkout',
      },
    );

    await LocalStorageService.addActivity(activity);
    await SyncService.queueForSync(
      action: 'create',
      collection: 'activities',
      data: activity.toMap(),
    );
  }

  /// Gets checkout statistics
  Map<String, dynamic> getCheckoutStats() {
    final allCheckouts = LocalStorageService.getAllCheckouts();
    final activeCheckouts = LocalStorageService.getActiveCheckouts();
    
    return {
      'totalCheckouts': allCheckouts.length,
      'activeCheckouts': activeCheckouts.length,
      'returnedCheckouts': allCheckouts.where((c) => c.isReturned).length,
      'pendingSync': allCheckouts.where((c) => !c.isSynced).length,
    };
  }

  /// Gets unsynced checkouts for manual sync
  List<EquipmentCheckout> getUnsyncedCheckouts() {
    return LocalStorageService.getAllCheckouts()
        .where((c) => !c.isSynced)
        .toList();
  }

  /// Parses checkout ID to extract components
  /// ID Format: YYHHMMSS-US-Room-XXXX
  CheckoutIdInfo? parseCheckoutId(String checkoutId) {
    try {
      final parts = checkoutId.split('-');
      if (parts.length < 4) return null;

      // First part: YYMMDDHHMMSS
      final dateTimePart = parts[0];
      if (dateTimePart.length < 6) return null;
      
      final year = 2000 + int.parse(dateTimePart.substring(0, 2));
      final hour = int.parse(dateTimePart.substring(2, 4));
      final minute = int.parse(dateTimePart.substring(4, 6));
      final second = dateTimePart.length >= 8 
          ? int.parse(dateTimePart.substring(6, 8)) 
          : 0;

      return CheckoutIdInfo(
        year: year,
        hour: hour,
        minute: minute,
        second: second,
        userInitials: parts[1],
        roomCode: parts[2],
        uniqueSuffix: parts[3],
      );
    } catch (e) {
      return null;
    }
  }
}

/// Information extracted from a checkout ID
class CheckoutIdInfo {
  final int year;
  final int hour;
  final int minute;
  final int second;
  final String userInitials;
  final String roomCode;
  final String uniqueSuffix;

  CheckoutIdInfo({
    required this.year,
    required this.hour,
    required this.minute,
    required this.second,
    required this.userInitials,
    required this.roomCode,
    required this.uniqueSuffix,
  });

  /// Returns formatted time string
  String get formattedTime => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:${second.toString().padLeft(2, '0')}';

  /// Returns formatted date string
  String get formattedDate => '$year';

  /// Returns a human-readable description
  String get description => 'Créé à $formattedTime par $userInitials pour salle $roomCode';
}
