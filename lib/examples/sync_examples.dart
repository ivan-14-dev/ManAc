import '../models/activity.dart';
import '../services/checkout_service.dart';
import '../services/return_service.dart';
import '../services/activity_sync_manager.dart';

/// Example usage demonstrating the checkout, return, and synchronization workflow
/// 
/// This file shows how to use the services for:
/// 1. Creating checkouts that work across devices
/// 2. Processing returns even from different devices
/// 3. Performing daily and weekly synchronization
/// 4. Validating synchronized data
class SyncExamples {
  final checkoutService = CheckoutService();
  final returnService = ReturnService();
  final activitySyncManager = ActivitySyncManager();

  // ========== Example 1: Creating a Checkout ==========
  
  /// Example: Creating a checkout on Device A
  /// This checkout can later be returned on Device B
  Future<void> exampleCreateCheckout() async {
    // On Device A - User borrows equipment
    final checkout = await checkoutService.createCheckout(
      equipmentId: 'EQ-001',
      equipmentName: 'Projecteur HDMI',
      equipmentPhotoPath: '/path/to/photo.jpg',
      borrowerName: 'Jean Dupont',
      borrowerCni: '123456789',
      cniPhotoPath: '/path/to/cni.jpg',
      destinationRoom: 'Salle A101',
      quantity: 1,
      userId: 'USER-001',
      userName: 'Marie Martin',
      notes: 'Pour présentation demain',
    );
    
    print('Checkout created: ${checkout.id}');
    // The checkout is now stored locally and queued for sync
  }

  // ========== Example 2: Returning Equipment (Same Device) ==========
  
  /// Example: Returning equipment using checkout ID (direct return)
  Future<void> exampleReturnById() async {
    final checkoutId = 'checkout-uuid-from-previous-checkout';
    
    try {
      final returnedCheckout = await returnService.returnByCheckoutId(
        checkoutId: checkoutId,
        userId: 'USER-001',
        userName: 'Marie Martin',
        notes: 'Équipement en bon état',
      );
      
      print('Equipment returned: ${returnedCheckout.id}');
      print('Return time: ${returnedCheckout.returnTime}');
    } catch (e) {
      print('Error: $e');
    }
  }

  // ========== Example 3: Returning Equipment (Different Device) ==========
  
  /// Example: Returning equipment on a different device
  /// The return service searches for the checkout by:
  /// - borrower name (Nom)
  /// - equipment name (Matériel)
  /// - destination room (Salle)
  /// - quantity (Quantité)
  Future<void> exampleReturnCrossDevice() async {
    // On Device B - User wants to return equipment borrowed on Device A
    // They provide: name, equipment, room, and optionally quantity
    
    // First, validate to see if we can find the checkout
    final validation = returnService.validateReturn(
      borrowerName: 'Jean Dupont',
      equipmentName: 'Projecteur HDMI',
      destinationRoom: 'Salle A101',
      quantity: 1,
    );
    
    if (validation.isValid && validation.checkout != null) {
      // Proceed with return
      final returnedCheckout = await returnService.returnBySearch(
        borrowerName: 'Jean Dupont',
        equipmentName: 'Projecteur HDMI',
        destinationRoom: 'Salle A101',
        quantity: 1,
        userId: 'USER-002',
        userName: 'Pierre Durant',
        notes: 'Retour confirmé',
      );
      
      print('Equipment returned successfully on different device!');
      print('Checkout ID: ${returnedCheckout?.id}');
    } else {
      print('Cannot return: ${validation.message}');
    }
  }

  // ========== Example 4: Daily Synchronization ==========
  
  /// Example: Performing daily synchronization
  /// The user who requests the sync will receive data to validate
  Future<void> exampleDailySync() async {
    const requestingUserId = 'USER-001';
    const requestingUserName = 'Marie Martin';
    
    // Step 1: Request daily sync
    final syncResult = await activitySyncManager.performDailySync(
      requestedByUserId: requestingUserId,
      requestedByUserName: requestingUserName,
    );
    
    print('=== Daily Sync Results ===');
    print('Date: ${syncResult.syncDate}');
    print('Requested by: ${syncResult.requestedBy}');
    print('Total activities: ${syncResult.totalActivities}');
    print('Total checkouts: ${syncResult.totalCheckouts}');
    print('Total returns: ${syncResult.totalReturns}');
    print('Pending sync: ${syncResult.pendingSync}');
    
    // Step 2: Display activities for validation
    print('\n=== Activities to Validate ===');
    for (final activity in syncResult.activities) {
      print('- ${activity.title}: ${activity.description}');
      print('  Type: ${activity.type}, Time: ${activity.timestamp}');
    }
    
    // Step 3: The requesting user validates the data
    // In a real app, this would be done through a UI
    print('\n=== Validation Required ===');
    print('Please review the above data and confirm synchronization.');
    print('User ${syncResult.requestedBy} must validate and confirm.');
    
    // Note: In actual implementation, user would click "Confirm" in UI
    // Then you'd call validateSyncData with the confirmed data
  }

  // ========== Example 5: Weekly Synchronization ==========
  
  /// Example: Performing weekly synchronization
  /// Provides detailed breakdown by day
  Future<void> exampleWeeklySync() async {
    const requestingUserId = 'USER-001';
    const requestingUserName = 'Marie Martin';
    
    // Step 1: Request weekly sync (current week)
    final syncResult = await activitySyncManager.performWeeklySync(
      requestedByUserId: requestingUserId,
      requestedByUserName: requestingUserName,
      weekOffset: 0, // Current week
    );
    
    print('=== Weekly Sync Results ===');
    print('Week: ${syncResult.weekStart} to ${syncResult.weekEnd}');
    print('Requested by: ${syncResult.requestedBy}');
    print('Total activities: ${syncResult.totalActivities}');
    print('Total checkouts: ${syncResult.totalCheckouts}');
    print('Total returns: ${syncResult.totalReturns}');
    
    // Step 2: Display daily breakdown
    print('\n=== Daily Breakdown ===');
    syncResult.dailyBreakdown.forEach((date, breakdown) {
      print('$date: ${breakdown.totalActivities} activities, '
            '${breakdown.totalCheckouts} checkouts, '
            '${breakdown.totalReturns} returns');
    });
    
    // Step 3: Display all checkouts for the week
    print('\n=== Checkouts This Week ===');
    for (final checkout in syncResult.checkouts) {
      print('- ${checkout.equipmentName} by ${checkout.borrowerName} '
            'to ${checkout.destinationRoom} (qty: ${checkout.quantity})');
    }
    
    // Step 4: The requesting user validates
    print('\n=== Validation Required ===');
    print('User ${syncResult.requestedBy} must review and confirm the data.');
  }

  // ========== Example 6: Weekly Sync for Previous Week ==========
  
  /// Example: Getting last week's data for comparison
  Future<void> exampleWeeklySyncLastWeek() async {
    final syncResult = await activitySyncManager.performWeeklySync(
      requestedByUserId: 'USER-001',
      requestedByUserName: 'Marie Martin',
      weekOffset: 1, // Last week
    );
    
    print('=== Last Week Summary ===');
    print('Activities: ${syncResult.totalActivities}');
    print('Checkouts: ${syncResult.totalCheckouts}');
    print('Returns: ${syncResult.totalReturns}');
  }

  // ========== Example 7: Validating Synchronized Data ==========
  
  /// Example: How the requesting user validates synchronized data
  Future<void> exampleValidateSyncData() async {
    // This would typically come from the sync result
    final localActivities = activitySyncManager.getActivitiesByDateRange(
      DateTime.now().subtract(const Duration(days: 7)),
      DateTime.now(),
    );
    
    // In a real scenario, remoteActivities would come from cloud
    // For now, we'll demonstrate with local data comparison
    final remoteActivities = localActivities.cast<Activity>();
    
    // The user who requested the sync validates the data
    final validationResult = activitySyncManager.validateSyncData(
      localActivities: localActivities,
      remoteActivities: remoteActivities,
      validatedByUserId: 'USER-001',
      validatedByUserName: 'Marie Martin',
    );
    
    print('=== Validation Results ===');
    print('Conflicts: ${validationResult.conflicts.length}');
    print('Local only: ${validationResult.localOnlyActivities.length}');
    print('Remote only: ${validationResult.remoteOnlyActivities.length}');
    print('Matched: ${validationResult.matchedActivities.length}');
    print('Validated by: ${validationResult.validatedBy}');
    
    // If there are conflicts, user would resolve them
    if (validationResult.conflicts.isNotEmpty) {
      print('\n=== Conflicts to Resolve ===');
      for (final conflict in validationResult.conflicts) {
        print('Activity: ${conflict.localActivity.title}');
        print('Differences: ${conflict.comparison.differences.join(", ")}');
        // User would choose: keepLocal, keepRemote, or merge
      }
    }
  }

  // ========== Example 8: Complete Workflow ==========
  
  /// Example: Complete workflow from checkout to sync validation
  Future<void> exampleCompleteWorkflow() async {
    // Simulate different devices/users
    const deviceAUserId = 'USER-A';
    const deviceAUserName = 'Alice DeviceA';
    const deviceBUserId = 'USER-B';
    const deviceBUserName = 'Bob DeviceB';
    
    // ===== DEVICE A: Create checkout =====
    print('=== Device A: Creating Checkout ===');
    final checkout = await checkoutService.createCheckout(
      equipmentId: 'EQ-002',
      equipmentName: 'Ordinateur Portable',
      equipmentPhotoPath: '',
      borrowerName: 'Claire Smith',
      borrowerCni: '987654321',
      cniPhotoPath: '',
      destinationRoom: 'Salle B202',
      quantity: 2,
      userId: deviceAUserId,
      userName: deviceAUserName,
    );
    print('Checkout created by ${deviceAUserName}');
    print('Checkout ID: ${checkout.id}');
    
    // ===== DEVICE B: Process return (cross-device) =====
    print('\n=== Device B: Processing Return ===');
    // Find and return the equipment
    final returned = await returnService.returnBySearch(
      borrowerName: 'Claire Smith',
      equipmentName: 'Ordinateur Portable',
      destinationRoom: 'Salle B202',
      quantity: 2,
      userId: deviceBUserId,
      userName: deviceBUserName,
    );
    print('Return processed by ${deviceBUserName}');
    print('Returned: ${returned?.id}');
    
    // ===== End of day: Daily sync =====
    print('\n=== End of Day: Daily Sync ===');
    final dailyResult = await activitySyncManager.performDailySync(
      requestedByUserId: deviceAUserId,
      requestedByUserName: deviceAUserName,
    );
    print('Daily sync completed');
    print('Total activities: ${dailyResult.totalActivities}');
    print('Checkouts: ${dailyResult.totalCheckouts}, Returns: ${dailyResult.totalReturns}');
    
    // ===== User validates =====
    print('\n=== User Validates Sync Data ===');
    print('${dailyResult.requestedBy} reviews and confirms the synchronized data');
    // In real app: User reviews in UI and clicks "Confirm"
    
    // ===== Weekly sync example =====
    print('\n=== Weekly Sync ===');
    final weeklyResult = await activitySyncManager.performWeeklySync(
      requestedByUserId: deviceAUserId,
      requestedByUserName: deviceAUserName,
    );
    print('Weekly sync completed');
    print('Week: ${weeklyResult.weekStart} to ${weeklyResult.weekEnd}');
    print('Total: ${weeklyResult.totalActivities} activities');
  }
}
