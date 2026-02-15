import 'package:uuid/uuid.dart';
import '../models/activity.dart';
import '../models/equipment_checkout.dart';
import 'local_storage_service.dart';
import 'sync_service.dart';

/// Manages synchronization of activities (checkouts and returns)
/// Compares by: name (borrower), material (equipment), room, and quantity
/// The requestor validates and confirms synchronized data
class ActivitySyncManager {
  static final ActivitySyncManager _instance = ActivitySyncManager._internal();
  factory ActivitySyncManager() => _instance;
  ActivitySyncManager._internal();

  final _uuid = const Uuid();

  // ========== Activity Management ==========

  /// Creates an activity for checkout or return
  Future<Activity> createActivity({
    required String type,
    required String title,
    required String description,
    required String userId,
    required String userName,
    Map<String, dynamic>? metadata,
  }) async {
    final activity = Activity(
      id: _uuid.v4(),
      type: type,
      title: title,
      description: description,
      userId: userId,
      userName: userName,
      metadata: metadata,
    );

    await LocalStorageService.addActivity(activity);
    await SyncService.queueForSync(
      action: 'create',
      collection: 'activities',
      data: activity.toMap(),
    );

    return activity;
  }

  /// Gets all activities
  List<Activity> getAllActivities() {
    return LocalStorageService.getAllActivities();
  }

  /// Gets recent activities
  List<Activity> getRecentActivities({int limit = 100}) {
    return LocalStorageService.getRecentActivities(limit: limit);
  }

  /// Gets activities by type (checkout, return, sync)
  List<Activity> getActivitiesByType(String type) {
    return LocalStorageService.getAllActivities()
        .where((a) => a.type == type)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Gets activities by date range
  List<Activity> getActivitiesByDateRange(DateTime start, DateTime end) {
    return LocalStorageService.getAllActivities()
        .where((a) => 
            a.timestamp.isAfter(start) && a.timestamp.isBefore(end) ||
            a.timestamp.isAtSameMomentAs(start) ||
            a.timestamp.isAtSameMomentAs(end))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  // ========== Comparison Methods ==========

  /// Compares two activities by name, material, room, and quantity
  ActivityComparisonResult compareActivities(Activity a, Activity b) {
    final aMeta = a.metadata ?? {};
    final bMeta = b.metadata ?? {};

    final aName = (aMeta['borrowerName'] ?? '').toString().toLowerCase().trim();
    final bName = (bMeta['borrowerName'] ?? '').toString().toLowerCase().trim();
    
    final aMaterial = (aMeta['equipmentName'] ?? '').toString().toLowerCase().trim();
    final bMaterial = (bMeta['equipmentName'] ?? '').toString().toLowerCase().trim();
    
    final aRoom = (aMeta['destinationRoom'] ?? '').toString().toLowerCase().trim();
    final bRoom = (bMeta['destinationRoom'] ?? '').toString().toLowerCase().trim();
    
    final aQuantity = aMeta['quantity'] ?? 0;
    final bQuantity = bMeta['quantity'] ?? 0;

    final nameMatch = aName == bName;
    final materialMatch = aMaterial == bMaterial;
    final roomMatch = aRoom == bRoom;
    final quantityMatch = aQuantity == bQuantity;

    return ActivityComparisonResult(
      areEqual: nameMatch && materialMatch && roomMatch && quantityMatch,
      nameMatch: nameMatch,
      materialMatch: materialMatch,
      roomMatch: roomMatch,
      quantityMatch: quantityMatch,
      differences: _getDifferences(nameMatch, materialMatch, roomMatch, quantityMatch),
    );
  }

  List<String> _getDifferences(
    bool nameMatch,
    bool materialMatch,
    bool roomMatch,
    bool quantityMatch,
  ) {
    final differences = <String>[];
    if (!nameMatch) differences.add('Nom (emprunteur)');
    if (!materialMatch) differences.add('Matériel');
    if (!roomMatch) differences.add('Salle');
    if (!quantityMatch) differences.add('Quantité');
    return differences;
  }

  /// Finds matching activity from another source (for sync comparison)
  Activity? findMatchingActivity(
    Activity localActivity, 
    List<Activity> remoteActivities,
  ) {
    for (final remote in remoteActivities) {
      final result = compareActivities(localActivity, remote);
      if (result.areEqual) {
        return remote;
      }
    }
    return null;
  }

  // ========== Checkout/Return Comparison ==========

  /// Compares checkouts by name, material, room, and quantity
  CheckoutComparisonResult compareCheckouts(
    EquipmentCheckout a, 
    EquipmentCheckout b,
  ) {
    final aName = a.borrowerName.toLowerCase().trim();
    final bName = b.borrowerName.toLowerCase().trim();
    
    final aMaterial = a.equipmentName.toLowerCase().trim();
    final bMaterial = b.equipmentName.toLowerCase().trim();
    
    final aRoom = a.destinationRoom.toLowerCase().trim();
    final bRoom = b.destinationRoom.toLowerCase().trim();

    final nameMatch = aName == bName;
    final materialMatch = aMaterial == bMaterial;
    final roomMatch = aRoom == bRoom;
    final quantityMatch = a.quantity == b.quantity;

    return CheckoutComparisonResult(
      areEqual: nameMatch && materialMatch && roomMatch && quantityMatch,
      nameMatch: nameMatch,
      materialMatch: materialMatch,
      roomMatch: roomMatch,
      quantityMatch: quantityMatch,
      differences: _getDifferences(nameMatch, materialMatch, roomMatch, quantityMatch),
    );
  }

  /// Finds matching checkout from list
  EquipmentCheckout? findMatchingCheckout(
    EquipmentCheckout checkout, 
    List<EquipmentCheckout> checkoutList,
  ) {
    for (final item in checkoutList) {
      final result = compareCheckouts(checkout, item);
      if (result.areEqual) {
        return item;
      }
    }
    return null;
  }

  // ========== Synchronization Methods ==========

  /// Performs daily synchronization
  /// Returns sync result with differences for user validation
  Future<DailySyncResult> performDailySync({
    required String requestedByUserId,
    required String requestedByUserName,
  }) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // Get local activities for today
    final localActivities = getActivitiesByDateRange(startOfDay, endOfDay);
    
    // Get local checkouts for today
    final localCheckouts = LocalStorageService.getCheckoutsByDateRange(startOfDay, endOfDay);

    // Categorize by type
    final checkouts = localActivities.where((a) => a.type == 'checkout').toList();
    final returns = localActivities.where((a) => a.type == 'return').toList();

    // Create sync activity
    await createActivity(
      type: 'sync',
      title: 'Synchronisation journalière',
      description: 'Synchronisation initiée par $requestedByUserName pour la date du ${_formatDate(startOfDay)}',
      userId: requestedByUserId,
      userName: requestedByUserName,
      metadata: {
        'syncType': 'daily',
        'date': startOfDay.toIso8601String(),
        'totalActivities': localActivities.length,
        'totalCheckouts': checkouts.length,
        'totalReturns': returns.length,
        'totalCheckoutsRecords': localCheckouts.length,
      },
    );

    return DailySyncResult(
      syncDate: startOfDay,
      requestedBy: requestedByUserName,
      totalActivities: localActivities.length,
      totalCheckouts: checkouts.length,
      totalReturns: returns.length,
      totalCheckoutRecords: localCheckouts.length,
      activities: localActivities,
      checkouts: localCheckouts,
      pendingSync: localActivities.where((a) => !a.isSynced).length,
      checkoutPendingSync: localCheckouts.where((c) => !c.isSynced).length,
    );
  }

  /// Performs weekly synchronization
  /// Returns sync result with differences for user validation
  Future<WeeklySyncResult> performWeeklySync({
    required String requestedByUserId,
    required String requestedByUserName,
    int? weekOffset, // 0 = current week, 1 = last week, etc.
  }) async {
    final now = DateTime.now();
    final weekOffsetValue = weekOffset ?? 0;
    
    // Calculate week start (Monday)
    final daysToSubtract = (now.weekday - 1) + (7 * weekOffsetValue);
    final weekStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysToSubtract));
    final weekEnd = weekStart.add(const Duration(days: 7));

    // Get local activities for the week
    final localActivities = getActivitiesByDateRange(weekStart, weekEnd);
    
    // Get local checkouts for the week
    final localCheckouts = LocalStorageService.getCheckoutsByDateRange(weekStart, weekEnd);

    // Categorize by type
    final checkouts = localActivities.where((a) => a.type == 'checkout').toList();
    final returns = localActivities.where((a) => a.type == 'return').toList();

    // Daily breakdown
    final Map<String, DailyBreakdown> dailyBreakdown = {};
    for (int i = 0; i < 7; i++) {
      final day = weekStart.add(Duration(days: i));
      final dayActivities = localActivities.where((a) => 
        a.timestamp.year == day.year && 
        a.timestamp.month == day.month && 
        a.timestamp.day == day.day
      ).toList();
      
      final dayCheckouts = dayActivities.where((a) => a.type == 'checkout').length;
      final dayReturns = dayActivities.where((a) => a.type == 'return').length;
      
      dailyBreakdown[_formatDate(day)] = DailyBreakdown(
        date: day,
        totalActivities: dayActivities.length,
        totalCheckouts: dayCheckouts,
        totalReturns: dayReturns,
      );
    }

    // Create sync activity
    await createActivity(
      type: 'sync',
      title: 'Synchronisation hebdomadaire',
      description: 'Synchronisation initiée par $requestedByUserName pour la semaine du ${_formatDate(weekStart)} au ${_formatDate(weekEnd.subtract(const Duration(days: 1)))}',
      userId: requestedByUserId,
      userName: requestedByUserName,
      metadata: {
        'syncType': 'weekly',
        'weekStart': weekStart.toIso8601String(),
        'weekEnd': weekEnd.toIso8601String(),
        'totalActivities': localActivities.length,
        'totalCheckouts': checkouts.length,
        'totalReturns': returns.length,
      },
    );

    return WeeklySyncResult(
      weekStart: weekStart,
      weekEnd: weekEnd,
      requestedBy: requestedByUserName,
      totalActivities: localActivities.length,
      totalCheckouts: checkouts.length,
      totalReturns: returns.length,
      totalCheckoutRecords: localCheckouts.length,
      dailyBreakdown: dailyBreakdown,
      activities: localActivities,
      checkouts: localCheckouts,
      pendingSync: localActivities.where((a) => !a.isSynced).length,
      checkoutPendingSync: localCheckouts.where((c) => !c.isSynced).length,
    );
  }

  /// Validates synchronized data - called by the one who requested sync
  /// Returns conflicts and allows user to choose which data to keep
  SyncValidationResult validateSyncData({
    required List<Activity> localActivities,
    required List<Activity> remoteActivities,
    required String validatedByUserId,
    required String validatedByUserName,
  }) {
    final conflicts = <ActivityConflict>[];
    final localOnly = <Activity>[];
    final remoteOnly = <Activity>[];
    final matched = <Activity>[];

    for (final local in localActivities) {
      final matching = findMatchingActivity(local, remoteActivities);
      
      if (matching == null) {
        localOnly.add(local);
      } else {
        matched.add(local);
        final comparison = compareActivities(local, matching);
        if (!comparison.areEqual) {
          conflicts.add(ActivityConflict(
            localActivity: local,
            remoteActivity: matching,
            comparison: comparison,
          ));
        }
      }
    }

    // Find remote-only activities
    for (final remote in remoteActivities) {
      if (!matched.any((local) => local.id == remote.id)) {
        final hasLocalMatch = localActivities.any((local) {
          final comparison = compareActivities(local, remote);
          return comparison.areEqual;
        });
        if (!hasLocalMatch) {
          remoteOnly.add(remote);
        }
      }
    }

    // Create validation activity
    createActivity(
      type: 'sync_validation',
      title: 'Validation de synchronisation',
      description: 'Données synchronisées validées par $validatedByUserName. Conflits: ${conflicts.length}, Locaux uniquement: ${localOnly.length}, Distants uniquement: ${remoteOnly.length}',
      userId: validatedByUserId,
      userName: validatedByUserName,
      metadata: {
        'validatedAt': DateTime.now().toIso8601String(),
        'totalConflicts': conflicts.length,
        'totalLocalOnly': localOnly.length,
        'totalRemoteOnly': remoteOnly.length,
        'totalMatched': matched.length,
      },
    );

    return SyncValidationResult(
      conflicts: conflicts,
      localOnlyActivities: localOnly,
      remoteOnlyActivities: remoteOnly,
      matchedActivities: matched,
      validatedBy: validatedByUserName,
      validatedAt: DateTime.now(),
    );
  }

  /// Resolves a conflict by choosing which data to keep
  Future<void> resolveConflict({
    required ActivityConflict conflict,
    required ConflictResolution resolution,
    required String resolvedByUserId,
    required String resolvedByUserName,
  }) async {
    Activity chosen;
    
    switch (resolution) {
      case ConflictResolution.keepLocal:
        chosen = conflict.localActivity;
        break;
      case ConflictResolution.keepRemote:
        chosen = conflict.remoteActivity;
        break;
      case ConflictResolution.merge:
        // Merge remote timestamp with local data
        chosen = conflict.localActivity.copyWith(
          timestamp: conflict.remoteActivity.timestamp,
          isSynced: false,
        );
        break;
    }

    // Update local storage with chosen version
    final allActivities = LocalStorageService.getAllActivities();
    final index = allActivities.indexWhere((a) => a.id == chosen.id);
    
    if (index >= 0) {
      allActivities[index] = chosen;
      // Note: In real implementation, you'd have a method to save activities
    }

    // Log resolution activity
    await createActivity(
      type: 'sync_resolution',
      title: 'Résolution de conflit',
      description: 'Conflit résolu par $resolvedByUserName. Résolution: ${resolution.name}',
      userId: resolvedByUserId,
      userName: resolvedByUserName,
      metadata: {
        'conflictActivityId': conflict.localActivity.id,
        'resolution': resolution.name,
      },
    );
  }

  // ========== Helper Methods ==========

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

// ========== Result Classes ==========

class ActivityComparisonResult {
  final bool areEqual;
  final bool nameMatch;
  final bool materialMatch;
  final bool roomMatch;
  final bool quantityMatch;
  final List<String> differences;

  ActivityComparisonResult({
    required this.areEqual,
    required this.nameMatch,
    required this.materialMatch,
    required this.roomMatch,
    required this.quantityMatch,
    required this.differences,
  });
}

class CheckoutComparisonResult {
  final bool areEqual;
  final bool nameMatch;
  final bool materialMatch;
  final bool roomMatch;
  final bool quantityMatch;
  final List<String> differences;

  CheckoutComparisonResult({
    required this.areEqual,
    required this.nameMatch,
    required this.materialMatch,
    required this.roomMatch,
    required this.quantityMatch,
    required this.differences,
  });
}

class DailySyncResult {
  final DateTime syncDate;
  final String requestedBy;
  final int totalActivities;
  final int totalCheckouts;
  final int totalReturns;
  final int totalCheckoutRecords;
  final List<Activity> activities;
  final List<EquipmentCheckout> checkouts;
  final int pendingSync;
  final int checkoutPendingSync;

  DailySyncResult({
    required this.syncDate,
    required this.requestedBy,
    required this.totalActivities,
    required this.totalCheckouts,
    required this.totalReturns,
    required this.totalCheckoutRecords,
    required this.activities,
    required this.checkouts,
    required this.pendingSync,
    required this.checkoutPendingSync,
  });
}

class WeeklySyncResult {
  final DateTime weekStart;
  final DateTime weekEnd;
  final String requestedBy;
  final int totalActivities;
  final int totalCheckouts;
  final int totalReturns;
  final int totalCheckoutRecords;
  final Map<String, DailyBreakdown> dailyBreakdown;
  final List<Activity> activities;
  final List<EquipmentCheckout> checkouts;
  final int pendingSync;
  final int checkoutPendingSync;

  WeeklySyncResult({
    required this.weekStart,
    required this.weekEnd,
    required this.requestedBy,
    required this.totalActivities,
    required this.totalCheckouts,
    required this.totalReturns,
    required this.totalCheckoutRecords,
    required this.dailyBreakdown,
    required this.activities,
    required this.checkouts,
    required this.pendingSync,
    required this.checkoutPendingSync,
  });
}

class DailyBreakdown {
  final DateTime date;
  final int totalActivities;
  final int totalCheckouts;
  final int totalReturns;

  DailyBreakdown({
    required this.date,
    required this.totalActivities,
    required this.totalCheckouts,
    required this.totalReturns,
  });
}

class ActivityConflict {
  final Activity localActivity;
  final Activity remoteActivity;
  final ActivityComparisonResult comparison;

  ActivityConflict({
    required this.localActivity,
    required this.remoteActivity,
    required this.comparison,
  });
}

enum ConflictResolution {
  keepLocal,
  keepRemote,
  merge,
}

class SyncValidationResult {
  final List<ActivityConflict> conflicts;
  final List<Activity> localOnlyActivities;
  final List<Activity> remoteOnlyActivities;
  final List<Activity> matchedActivities;
  final String validatedBy;
  final DateTime validatedAt;

  SyncValidationResult({
    required this.conflicts,
    required this.localOnlyActivities,
    required this.remoteOnlyActivities,
    required this.matchedActivities,
    required this.validatedBy,
    required this.validatedAt,
  });

  int get totalIssues => conflicts.length + localOnlyActivities.length + remoteOnlyActivities.length;
}
