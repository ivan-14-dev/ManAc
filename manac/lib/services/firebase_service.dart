// ========================================
// Service Firebase pour la gestion Realtime Database
// Permet les opérations CRUD sur la base de données temps réel
// et la synchronisation avec le stockage Firebase
// ========================================

import 'package:firebase_database/firebase_database.dart';
import '../models/stock_item.dart';
import '../models/stock_movement.dart';
import '../models/activity.dart';
import '../models/equipment_checkout.dart';

// Classe de service pour les opérations Firebase Realtime Database
class FirebaseService {
  // Instance singleton de Realtime Database
  static final FirebaseDatabase _database = FirebaseDatabase.instance;
  
  // Nœuds de la base de données
  static const String _stockNode = 'stock_items';
  static const String _movementsNode = 'stock_movements';
  static const String _activitiesNode = 'activities';
  static const String _checkoutsNode = 'equipment_checkouts';

  // ========================================
  // OPÉRATIONS SUR LES ARTICLES DE STOCK
  // ========================================

  // Créer un nouvel article de stock dans Realtime Database
  static Future<String> createStockItem(StockItem item) async {
    final ref = _database.ref(_stockNode);
    final newRef = ref.push();
    await newRef.set({
      'id': item.id,
      'firebaseId': newRef.key,
      'name': item.name,
      'category': item.category,
      'quantity': item.quantity,
      'minQuantity': item.minQuantity,
      'unit': item.unit,
      'price': item.price,
      'description': item.description,
      'barcode': item.barcode,
      'location': item.location,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
    return newRef.key!;
  }

  // Mettre à jour un article de stock existant
  static Future<void> updateStockItem(StockItem item) async {
    final firebaseId = item.firebaseId ?? item.id;
    final ref = _database.ref(_stockNode).child(firebaseId);
    await ref.update({
      'name': item.name,
      'category': item.category,
      'quantity': item.quantity,
      'minQuantity': item.minQuantity,
      'unit': item.unit,
      'price': item.price,
      'description': item.description,
      'barcode': item.barcode,
      'location': item.location,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // Supprimer un article de stock
  static Future<void> deleteStockItem(String firebaseId) async {
    await _database.ref(_stockNode).child(firebaseId).remove();
  }

  // Obtenir un flux temps réel des articles de stock (stream)
  static Stream<List<StockItem>> getStockItems() {
    return _database
        .ref(_stockNode)
        .orderByChild('name')
        .onValue
        .map((event) {
      final data = event.snapshot.value;
      if (data == null) return [];
      if (data is! Map) return [];
      
      final Map<dynamic, dynamic> dataMap = data;
      return dataMap.entries.map((entry) {
        final Map<String, dynamic> itemData = {
          ...Map<String, dynamic>.from(entry.value),
          'firebaseId': entry.key,
        };
        return StockItem.fromMap(itemData);
      }).toList();
    });
  }

  // Récupérer les articles de stock une seule fois
  static Future<List<StockItem>> fetchStockItems() async {
    final snapshot = await _database.ref(_stockNode).get();
    final data = snapshot.value;
    if (data == null) return [];
    if (data is! Map) return [];
    
    final Map<dynamic, dynamic> dataMap = data;
    return dataMap.entries.map((entry) {
      final Map<String, dynamic> itemData = {
        ...Map<String, dynamic>.from(entry.value),
        'firebaseId': entry.key,
      };
      return StockItem.fromMap(itemData);
    }).toList();
  }

  // ========================================
  // OPÉRATIONS SUR LES MOUVEMENTS DE STOCK
  // ========================================

  // Créer un nouveau mouvement de stock (entrée/sortie)
  static Future<String> createMovement(StockMovement movement) async {
    final ref = _database.ref(_movementsNode);
    final newRef = ref.push();
    await newRef.set({
      'id': movement.id,
      'firebaseId': newRef.key,
      'stockItemId': movement.stockItemId,
      'type': movement.type,
      'quantity': movement.quantity,
      'reason': movement.reason,
      'reference': movement.reference,
      'date': movement.date.toIso8601String(),
      'userId': movement.userId,
      'userName': movement.userName,
      'createdAt': DateTime.now().toIso8601String(),
    });
    return newRef.key!;
  }

  // Obtenir un flux temps réel des mouvements de stock
  static Stream<List<StockMovement>> getMovements({int limit = 50}) {
    return _database
        .ref(_movementsNode)
        .orderByChild('date')
        .limitToLast(limit)
        .onValue
        .map((event) {
      final data = event.snapshot.value;
      if (data == null) return [];
      if (data is! Map) return [];
      
      final Map<dynamic, dynamic> dataMap = data;
      final movements = dataMap.entries.map((entry) {
        final Map<String, dynamic> itemData = {
          ...Map<String, dynamic>.from(entry.value),
          'firebaseId': entry.key,
        };
        return StockMovement.fromMap(itemData);
      }).toList();
      
      // Trier par date décroissant
      movements.sort((a, b) => b.date.compareTo(a.date));
      return movements;
    });
  }

  // Récupérer les mouvements de stock une seule fois
  static Future<List<StockMovement>> fetchMovements() async {
    final snapshot = await _database.ref(_movementsNode).get();
    final data = snapshot.value;
    if (data == null) return [];
    if (data is! Map) return [];
    
    final Map<dynamic, dynamic> dataMap = data;
    final movements = dataMap.entries.map((entry) {
      final Map<String, dynamic> itemData = {
        ...Map<String, dynamic>.from(entry.value),
        'firebaseId': entry.key,
      };
      return StockMovement.fromMap(itemData);
    }).toList();
    
    // Trier par date décroissant
    movements.sort((a, b) => b.date.compareTo(a.date));
    return movements;
  }

  // ========================================
  // OPÉRATIONS SUR LES ACTIVITÉS
  // ========================================

  // Créer une nouvelle activité dans le journal
  static Future<String> createActivity(Activity activity) async {
    final ref = _database.ref(_activitiesNode);
    final newRef = ref.push();
    await newRef.set({
      'id': activity.id,
      'firebaseId': newRef.key,
      'type': activity.type,
      'title': activity.title,
      'description': activity.description,
      'timestamp': activity.timestamp.toIso8601String(),
      'userId': activity.userId,
      'userName': activity.userName,
      'metadata': activity.metadata,
      'createdAt': DateTime.now().toIso8601String(),
    });
    return newRef.key!;
  }

  // Obtenir un flux temps réel des activités
  static Stream<List<Activity>> getActivities({int limit = 100}) {
    return _database
        .ref(_activitiesNode)
        .orderByChild('timestamp')
        .limitToLast(limit)
        .onValue
        .map((event) {
      final data = event.snapshot.value;
      if (data == null) return [];
      if (data is! Map) return [];
      
      final Map<dynamic, dynamic> dataMap = data;
      final activities = dataMap.entries.map((entry) {
        final Map<String, dynamic> itemData = {
          ...Map<String, dynamic>.from(entry.value),
          'firebaseId': entry.key,
        };
        return Activity.fromMap(itemData);
      }).toList();
      
      // Trier par timestamp décroissant
      activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return activities;
    });
  }

  // ========================================
  // OPÉRATIONS PAR LOT (BATCH)
  // ========================================

  // Créer plusieurs articles en une seule opération batch
  // Utile pour la synchronisation initiale
  static Future<void> batchCreateItems(List<StockItem> items) async {
    final updates = <String, dynamic>{};
    
    for (final item in items) {
      final ref = _database.ref(_stockNode).push();
      updates['${_stockNode}/${ref.key}'] = {
        'id': item.id,
        'firebaseId': ref.key,
        'name': item.name,
        'category': item.category,
        'quantity': item.quantity,
        'minQuantity': item.minQuantity,
        'unit': item.unit,
        'price': item.price,
        'description': item.description,
        'barcode': item.barcode,
        'location': item.location,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };
    }
    
    await _database.ref().update(updates);
  }

  // ========================================
  // VÉRIFICATION DE CONNEXION
  // ========================================

  // Vérifier si la connexion à Firebase est active
  static Future<bool> checkConnection() async {
    try {
      // Test simple - écrire et lire un noeud de test
      final testRef = _database.ref('connection_test').child('test');
      await testRef.set({'timestamp': DateTime.now().millisecondsSinceEpoch});
      final snapshot = await testRef.get();
      await testRef.remove(); // Nettoyer
      return snapshot.exists;
    } catch (e) {
      print('Erreur de connexion Firebase: $e');
      return false;
    }
  }

  // Tester la connexion et retourner les détails
  static Future<Map<String, dynamic>> testConnection() async {
    try {
      final startTime = DateTime.now();
      final testRef = _database.ref('connection_test').child('test_${DateTime.now().millisecondsSinceEpoch}');
      await testRef.set({'test': true, 'timestamp': DateTime.now().toIso8601String()});
      
      final snapshot = await testRef.get();
      final success = snapshot.exists;
      
      await testRef.remove();
      
      return {
        'success': success,
        'responseTime': DateTime.now().difference(startTime).inMilliseconds,
        'data': snapshot.value,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // ========================================
  // OPÉRATIONS SUR LES EMPRUNTS D'ÉQUIPEMENTS
  // ========================================

  // Récupérer un emprunt par son ID (pour les retours cross-device)
  static Future<EquipmentCheckout?> getCheckoutById(String checkoutId) async {
    try {
      final snapshot = await _database
          .ref(_checkoutsNode)
          .orderByChild('id')
          .equalTo(checkoutId)
          .limitToFirst(1)
          .get();
      
      final data = snapshot.value;
      if (data == null) return null;
      if (data is! Map) return null;
      
      final Map<dynamic, dynamic> dataMap = data;
      if (dataMap.isEmpty) return null;
      
      final entry = dataMap.entries.first;
      final Map<String, dynamic> itemData = {
        ...Map<String, dynamic>.from(entry.value),
        'firebaseId': entry.key,
      };
      return EquipmentCheckout.fromMap(itemData);
    } catch (e) {
      return null;
    }
  }

  // Récupérer tous les emprunts actifs (non retournés)
  static Future<List<EquipmentCheckout>> getActiveCheckouts() async {
    try {
      final snapshot = await _database
          .ref(_checkoutsNode)
          .orderByChild('isReturned')
          .equalTo(false)
          .get();
      
      final data = snapshot.value;
      if (data == null) return [];
      if (data is! Map) return [];
      
      final Map<dynamic, dynamic> dataMap = data;
      return dataMap.entries.map((entry) {
        final Map<String, dynamic> itemData = {
          ...Map<String, dynamic>.from(entry.value),
          'firebaseId': entry.key,
        };
        return EquipmentCheckout.fromMap(itemData);
      }).toList();
    } catch (e) {
      return [];
    }
  }
}
