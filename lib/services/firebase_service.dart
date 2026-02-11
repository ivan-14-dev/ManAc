import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/stock_item.dart';
import '../models/stock_movement.dart';
import '../models/activity.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  static const String _stockCollection = 'stock_items';
  static const String _movementsCollection = 'stock_movements';
  static const String _activitiesCollection = 'activities';

  // Stock Items
  static Future<String> createStockItem(StockItem item) async {
    final docRef = await _firestore.collection(_stockCollection).add({
      'id': item.id,
      'name': item.name,
      'category': item.category,
      'quantity': item.quantity,
      'minQuantity': item.minQuantity,
      'unit': item.unit,
      'price': item.price,
      'description': item.description,
      'barcode': item.barcode,
      'location': item.location,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  static Future<void> updateStockItem(StockItem item) async {
    await _firestore.collection(_stockCollection).doc(item.firebaseId).update({
      'name': item.name,
      'category': item.category,
      'quantity': item.quantity,
      'minQuantity': item.minQuantity,
      'unit': item.unit,
      'price': item.price,
      'description': item.description,
      'barcode': item.barcode,
      'location': item.location,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteStockItem(String firebaseId) async {
    await _firestore.collection(_stockCollection).doc(firebaseId).delete();
  }

  static Stream<List<StockItem>> getStockItems() {
    return _firestore
        .collection(_stockCollection)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['firebaseId'] = doc.id;
        return StockItem.fromMap(data);
      }).toList();
    });
  }

  static Future<List<StockItem>> fetchStockItems() async {
    final snapshot = await _firestore.collection(_stockCollection).get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['firebaseId'] = doc.id;
      return StockItem.fromMap(data);
    }).toList();
  }

  // Stock Movements
  static Future<String> createMovement(StockMovement movement) async {
    final docRef = await _firestore.collection(_movementsCollection).add({
      'id': movement.id,
      'stockItemId': movement.stockItemId,
      'type': movement.type,
      'quantity': movement.quantity,
      'reason': movement.reason,
      'reference': movement.reference,
      'date': movement.date.toIso8601String(),
      'userId': movement.userId,
      'userName': movement.userName,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  static Stream<List<StockMovement>> getMovements({int limit = 50}) {
    return _firestore
        .collection(_movementsCollection)
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['firebaseId'] = doc.id;
        return StockMovement.fromMap(data);
      }).toList();
    });
  }

  static Future<List<StockMovement>> fetchMovements() async {
    final snapshot = await _firestore
        .collection(_movementsCollection)
        .orderBy('date', descending: true)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['firebaseId'] = doc.id;
      return StockMovement.fromMap(data);
    }).toList();
  }

  // Activities
  static Future<String> createActivity(Activity activity) async {
    final docRef = await _firestore.collection(_activitiesCollection).add({
      'id': activity.id,
      'type': activity.type,
      'title': activity.title,
      'description': activity.description,
      'timestamp': activity.timestamp.toIso8601String(),
      'userId': activity.userId,
      'userName': activity.userName,
      'metadata': activity.metadata,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  static Stream<List<Activity>> getActivities({int limit = 100}) {
    return _firestore
        .collection(_activitiesCollection)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['firebaseId'] = doc.id;
        return Activity.fromMap(data);
      }).toList();
    });
  }

  // Batch operations for sync
  static Future<void> batchCreateItems(List<StockItem> items) async {
    final batch = _firestore.batch();
    
    for (final item in items) {
      final docRef = _firestore.collection(_stockCollection).doc();
      batch.set(docRef, {
        'id': item.id,
        'name': item.name,
        'category': item.category,
        'quantity': item.quantity,
        'minQuantity': item.minQuantity,
        'unit': item.unit,
        'price': item.price,
        'description': item.description,
        'barcode': item.barcode,
        'location': item.location,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    
    await batch.commit();
  }

  // Connection status
  static Future<bool> checkConnection() async {
    try {
      await _firestore.collection('connection_check').doc('test').get();
      return true;
    } catch (e) {
      return false;
    }
  }
}
