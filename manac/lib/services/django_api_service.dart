// ========================================
// Service API Django
// Communication directe avec le backend Django
// ========================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/equipment.dart';
import '../models/equipment_checkout.dart';
import '../models/activity.dart';
import '../models/daily_report.dart';
import '../models/stock_item.dart';
import '../models/stock_movement.dart';
import 'manac_config_service.dart';

/// Configuration de l'API Django
class DjangoApiConfig {
  static String get baseUrl => ManacConfigService.localApiUrl;
  
  static const String _apiPrefix = '/api';
  
  // Endpoints
  static const String authLogin = '$_apiPrefix/auth/login/';
  static const String authLogout = '$_apiPrefix/auth/logout/';
  static const String authMe = '$_apiPrefix/auth/me/';
  
  static const String users = '$_apiPrefix/users/';
  static const String departments = '$_apiPrefix/departments/';
  static const String equipment = '$_apiPrefix/equipment/';
  static const String borrowings = '$_apiPrefix/borrowings/';
  static const String activities = '$_apiPrefix/activities/';
  static const String stock = '$_apiPrefix/stock/';
  static const String stockMovements = '$_apiPrefix/stock-movements/';
  static const String reports = '$_apiPrefix/reports/';
}

/// Service principal pour l'API Django
class DjangoApiService {
  String? _token;
  
  // Singleton
  static final DjangoApiService _instance = DjangoApiService._internal();
  factory DjangoApiService() => _instance;
  DjangoApiService._internal();
  
  // Getter/Setter pour le token
  String? get token => _token;
  set token(String? value) => _token = value;
  
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;
  
  /// Headers par défaut
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_token != null) 'Authorization': 'Token $_token',
  };
  
  // ==================== AUTH ====================
  
  /// Connexion utilisateur
  Future<AuthResponse> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${DjangoApiConfig.authLogin}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['token'] ?? data['access'] ?? '';
        return AuthResponse(success: true, user: data);
      } else {
        return AuthResponse(
          success: false, 
          error: 'Erreur de connexion: ${response.statusCode}',
        );
      }
    } catch (e) {
      return AuthResponse(success: false, error: e.toString());
    }
  }
  
  /// Déconnexion
  Future<void> logout() async {
    if (_token == null) return;
    
    try {
      await http.post(
        Uri.parse(DjangoApiConfig.authLogout),
        headers: _headers,
      );
    } catch (_) {}
    
    _token = null;
  }
  
  /// Obtenir l'utilisateur actuel
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final response = await http.get(
        Uri.parse(DjangoApiConfig.authMe),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
  
  // ==================== EQUIPMENT ====================
  
  /// Liste des équipements
  Future<List<Equipment>> getEquipment({Map<String, String>? params}) async {
    try {
      final uri = Uri.parse(DjangoApiConfig.equipment).replace(queryParameters: params);
      final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] ?? data;
        return (results as List).map((e) => _equipmentFromJson(e)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
  
  /// Créer un équipement
  Future<Equipment?> createEquipment(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse(DjangoApiConfig.equipment),
        headers: _headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 201) {
        return _equipmentFromJson(jsonDecode(response.body));
      }
      return null;
    } catch (_) {
      return null;
    }
  }
  
  /// Mettre à jour un équipement
  Future<Equipment?> updateEquipment(String id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('${DjangoApiConfig.equipment}$id/'),
        headers: _headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        return _equipmentFromJson(jsonDecode(response.body));
      }
      return null;
    } catch (_) {
      return null;
    }
  }
  
  /// Supprimer un équipement
  Future<bool> deleteEquipment(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('${DjangoApiConfig.equipment}$id/'),
        headers: _headers,
      ).timeout(const Duration(seconds: 30));
      
      return response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }
  
  // ==================== BORROWINGS ====================
  
  /// Liste des emprunts
  Future<List<EquipmentCheckout>> getBorrowings({Map<String, String>? params}) async {
    try {
      final uri = Uri.parse(DjangoApiConfig.borrowings).replace(queryParameters: params);
      final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] ?? data;
        return (results as List).map((e) => _checkoutFromJson(e)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
  
  /// Créer un emprunt
  Future<EquipmentCheckout?> createBorrowing(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse(DjangoApiConfig.borrowings),
        headers: _headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 201) {
        return _checkoutFromJson(jsonDecode(response.body));
      }
      return null;
    } catch (_) {
      return null;
    }
  }
  
  /// Approuver un emprunt
  Future<bool> approveBorrowing(String id) async {
    try {
      final response = await http.post(
        Uri.parse('${DjangoApiConfig.borrowings}$id/approve/'),
        headers: _headers,
      ).timeout(const Duration(seconds: 30));
      
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
  
  /// Rejeter un emprunt
  Future<bool> rejectBorrowing(String id, String reason) async {
    try {
      final response = await http.post(
        Uri.parse('${DjangoApiConfig.borrowings}$id/reject/'),
        headers: _headers,
        body: jsonEncode({'rejection_reason': reason}),
      ).timeout(const Duration(seconds: 30));
      
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
  
  /// Remise d'équipement (checkout)
  Future<bool> checkoutBorrowing(String id) async {
    try {
      final response = await http.post(
        Uri.parse('${DjangoApiConfig.borrowings}$id/checkout/'),
        headers: _headers,
      ).timeout(const Duration(seconds: 30));
      
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
  
  /// Retour d'équipement
  Future<bool> returnBorrowing(String id, {String? notes}) async {
    try {
      final response = await http.post(
        Uri.parse('${DjangoApiConfig.borrowings}$id/return_equipment/'),
        headers: _headers,
        body: jsonEncode({'condition_notes': notes ?? ''}),
      ).timeout(const Duration(seconds: 30));
      
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
  
  // ==================== STOCK ====================
  
  /// Liste des articles en stock
  Future<List<StockItem>> getStockItems({Map<String, String>? params}) async {
    try {
      final uri = Uri.parse(DjangoApiConfig.stock).replace(queryParameters: params);
      final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] ?? data;
        return (results as List).map((e) => _stockItemFromJson(e)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
  
  /// Créer un article en stock
  Future<StockItem?> createStockItem(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse(DjangoApiConfig.stock),
        headers: _headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 201) {
        return _stockItemFromJson(jsonDecode(response.body));
      }
      return null;
    } catch (_) {
      return null;
    }
  }
  
  /// Mouvement de stock
  Future<StockMovement?> createStockMovement(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse(DjangoApiConfig.stockMovements),
        headers: _headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 201) {
        return _stockMovementFromJson(jsonDecode(response.body));
      }
      return null;
    } catch (_) {
      return null;
    }
  }
  
  // ==================== ACTIVITIES ====================
  
  /// Liste des activités
  Future<List<Activity>> getActivities({Map<String, String>? params}) async {
    try {
      final uri = Uri.parse(DjangoApiConfig.activities).replace(queryParameters: params);
      final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] ?? data;
        return (results as List).map((e) => _activityFromJson(e)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
  
  /// Créer une activité
  Future<Activity?> createActivity(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse(DjangoApiConfig.activities),
        headers: _headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 201) {
        return _activityFromJson(jsonDecode(response.body));
      }
      return null;
    } catch (_) {
      return null;
    }
  }
  
  // ==================== REPORTS ====================
  
  /// Obtenir les rapports
  Future<List<DailyReport>> getReports({int days = 7}) async {
    try {
      final response = await http.get(
        Uri.parse('${DjangoApiConfig.reports}recent/?days=$days'),
        headers: _headers,
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] ?? data;
        return (results as List).map((e) => _reportFromJson(e)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
  
  /// Générer un rapport
  Future<DailyReport?> generateReport({String? date}) async {
    try {
      final response = await http.post(
        Uri.parse('${DjangoApiConfig.reports}generate/'),
        headers: _headers,
        body: jsonEncode(date != null ? {'date': date} : {}),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        return _reportFromJson(jsonDecode(response.body));
      }
      return null;
    } catch (_) {
      return null;
    }
  }
  
  // ==================== HELPERS ====================
  
  Equipment _equipmentFromJson(Map<String, dynamic> json) {
    return Equipment(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      serialNumber: json['serial_number'] ?? '',
      barcode: json['barcode'],
      location: json['location'] ?? '',
      status: json['status'] ?? 'available',
      totalQuantity: json['total_quantity'] ?? 1,
      availableQuantity: json['available_quantity'] ?? 1,
      photoPath: json['photo'],
      value: (json['value'] ?? 0).toDouble(),
      purchaseDate: json['purchase_date'] != null 
          ? DateTime.tryParse(json['purchase_date']) 
          : null,
    );
  }
  
  EquipmentCheckout _checkoutFromJson(Map<String, dynamic> json) {
    return EquipmentCheckout(
      id: json['id']?.toString() ?? '',
      equipmentId: json['equipment']?.toString() ?? '',
      equipmentName: json['equipment_name'] ?? '',
      borrowerName: json['borrower_name'] ?? '',
      borrowerCni: json['borrower_cni'] ?? '',
      borrowerEmail: json['borrower_email'] ?? '',
      destinationRoom: json['destination_room'] ?? '',
      quantity: json['quantity'] ?? 1,
      checkoutTime: json['checkout_date'] != null 
          ? DateTime.tryParse(json['checkout_date']) ?? DateTime.now()
          : DateTime.now(),
      isReturned: json['status'] == 'returned',
      returnTime: json['actual_return_date'] != null 
          ? DateTime.tryParse(json['actual_return_date'])
          : null,
      notes: json['notes'],
    );
  }
  
  Activity _activityFromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id']?.toString() ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      timestamp: json['timestamp'] != null 
          ? DateTime.tryParse(json['timestamp']) ?? DateTime.now()
          : DateTime.now(),
      userId: json['user']?.toString(),
      userName: json['user_name'],
      metadata: json['metadata'],
      isSynced: true,
    );
  }
  
  DailyReport _reportFromJson(Map<String, dynamic> json) {
    return DailyReport(
      id: json['id']?.toString() ?? '',
      date: json['date'] != null 
          ? DateTime.tryParse(json['date']) ?? DateTime.now()
          : DateTime.now(),
      totalCheckouts: json['total_checkouts'] ?? 0,
      totalReturns: json['total_returns'] ?? 0,
      totalItemsCheckedOut: json['total_items_checked_out'] ?? 0,
      totalItemsReturned: json['total_items_returned'] ?? 0,
      checkoutIds: List<String>.from(json['checkout_ids'] ?? []),
      returnIds: List<String>.from(json['return_ids'] ?? []),
      summary: json['summary'] ?? '',
      generatedBy: json['generated_by_name'] ?? '',
      generatedAt: json['generated_at'] != null 
          ? DateTime.tryParse(json['generated_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
  
  StockItem _stockItemFromJson(Map<String, dynamic> json) {
    return StockItem(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      quantity: json['quantity'] ?? 0,
      minQuantity: json['min_quantity'] ?? 0,
      unit: json['unit'] ?? 'pcs',
      price: (json['price'] ?? 0).toDouble(),
      description: json['description'],
      barcode: json['barcode'],
      location: json['location'] ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.tryParse(json['updated_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
  
  StockMovement _stockMovementFromJson(Map<String, dynamic> json) {
    return StockMovement(
      id: json['id']?.toString() ?? '',
      stockItemId: json['stock_item']?.toString() ?? '',
      type: json['type'] ?? 'adjustment',
      quantity: json['quantity'] ?? 0,
      reason: json['reason'],
      reference: json['reference'],
      date: json['date'] != null 
          ? DateTime.tryParse(json['date']) ?? DateTime.now()
          : DateTime.now(),
      userId: json['user']?.toString(),
      userName: json['user_name'],
    );
  }
}

/// Réponse d'authentification
class AuthResponse {
  final bool success;
  final Map<String, dynamic>? user;
  final String? token;
  final String? error;
  
  AuthResponse({
    required this.success,
    this.user,
    this.token,
    this.error,
  });
}
