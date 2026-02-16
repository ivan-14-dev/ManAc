// ========================================
// Service Firebase pour la gestion Cloud Firestore
// Permet les opérations CRUD sur les collections Firestore
// et la synchronisation avec le stockage Firebase
// ========================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/stock_item.dart';
import '../models/stock_movement.dart';
import '../models/activity.dart';
import '../models/equipment_checkout.dart';

// Classe de service pour les opérations Firebase
class FirebaseService {
  // Instance singleton de Firestore
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Noms des collections Firestore
  static const String _stockCollection = 'stock_items';
  static const String _movementsCollection = 'stock_movements';
  static const String _activitiesCollection = 'activities';
  static const String _checkoutsCollection = 'equipment_checkouts';

  // ========================================
  // OPÉRATIONS SUR LES ARTICLES DE STOCK
  // ========================================

  // Créer un nouvel article de stock dans Firestore
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

  // Mettre à jour un article de stock existant
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

  // Supprimer un article de stock
  static Future<void> deleteStockItem(String firebaseId) async {
    await _firestore.collection(_stockCollection).doc(firebaseId).delete();
  }

  // Obtenir un flux temps réel des articles de stock (stream)
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

  // Récupérer les articles de stock une seule fois
  static Future<List<StockItem>> fetchStockItems() async {
    final snapshot = await _firestore.collection(_stockCollection).get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['firebaseId'] = doc.id;
      return StockItem.fromMap(data);
    }).toList();
  }

  // ========================================
  // OPÉRATIONS SUR LES MOUVEMENTS DE STOCK
  // ========================================

  // Créer un nouveau mouvement de stock (entrée/sortie)
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

  // Obtenir un flux temps réel des mouvements de stock
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

  // Récupérer les mouvements de stock une seule fois
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

  // ========================================
  // OPÉRATIONS SUR LES ACTIVITÉS
  // ========================================

  // Créer une nouvelle activité dans le journal
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

  // Obtenir un flux temps réel des activités
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

  // ========================================
  // OPÉRATIONS PAR LOT (BATCH)
  // ========================================

  // Créer plusieurs articles en une seule opération batch
  // Utile pour la synchronisation initiale
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

  // ========================================
  // VÉRIFICATION DE CONNEXION
  // ========================================

  // Vérifier si la connexion à Firebase est active
  static Future<bool> checkConnection() async {
    try {
      await _firestore.collection('connection_check').doc('test').get();
      return true;
    } catch (e) {
      return false;
    }
  }

  // ========================================
  // OPÉRATIONS SUR LES EMPRUNTS D'ÉQUIPEMENTS
  // ========================================

  // Récupérer un emprunt par son ID (pour les retours cross-device)
  static Future<EquipmentCheckout?> getCheckoutById(String checkoutId) async {
    try {
      final snapshot = await _firestore
          .collection(_checkoutsCollection)
          .where('id', isEqualTo: checkoutId)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) {
        return null;
      }
      
      final data = snapshot.docs.first.data();
      data['firebaseId'] = snapshot.docs.first.id;
      return EquipmentCheckout.fromMap(data);
    } catch (e) {
      return null;
    }
  }

  // Récupérer tous les emprunts actifs (non retournés)
  static Future<List<EquipmentCheckout>> getActiveCheckouts() async {
    try {
      final snapshot = await _firestore
          .collection(_checkoutsCollection)
          .where('isReturned', isEqualTo: false)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['firebaseId'] = doc.id;
        return EquipmentCheckout.fromMap(data);
      }).toList();
    } catch (e) {
      return [];
    }
  }
}
