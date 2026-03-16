// ========================================
// Modèle utilisateur pour l'API locale
// ========================================

class User {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final String? department;
  final String? role;
  final String? token;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    this.department,
    this.role,
    this.token,
    this.createdAt,
  });

  /// Crée un utilisateur depuis la réponse de l'API locale
  factory User.fromLocalApi(Map<String, dynamic> data, String token) {
    return User(
      id: data['id']?.toString() ?? data['_id']?.toString() ?? '',
      email: data['email'] ?? '',
      name: data['name'] ?? data['username'] ?? '',
      phone: data['phone'],
      department: data['department'],
      role: data['role'] ?? data['type'],
      token: token,
      createdAt: data['createdAt'] != null 
          ? DateTime.tryParse(data['createdAt'].toString())
          : null,
    );
  }

  /// Convertir en Map pour le stockage local
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'department': department,
      'role': role,
      'token': token,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  /// Créer depuis un Map
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'],
      department: map['department'],
      role: map['role'],
      token: map['token'],
      createdAt: map['createdAt'] != null 
          ? DateTime.tryParse(map['createdAt'])
          : null,
    );
  }

  /// Vérifie si l'utilisateur est admin
  bool get isAdmin => role == 'admin' || role == 'administrator';

  /// Vérifie si l'utilisateur est un technician
  bool get isTechnician => role == 'technician' || role == 'tech';
}
