import 'package:uuid/uuid.dart';

class Equipment {
  String id;
  String name;
  String category;
  String description;
  String serialNumber;
  String? barcode;
  String location;
  String status; // 'available', 'checked_out', 'maintenance', 'retired'
  int totalQuantity;
  int availableQuantity;
  String? photoPath;
  double value;
  DateTime purchaseDate;
  DateTime createdAt;
  DateTime updatedAt;
  String userId;
  String userName;
  bool isSynced;

  Equipment({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.serialNumber,
    this.barcode,
    required this.location,
    required this.status,
    required this.totalQuantity,
    required this.availableQuantity,
    this.photoPath,
    required this.value,
    required this.purchaseDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    required this.userId,
    required this.userName,
    this.isSynced = false,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'description': description,
      'serialNumber': serialNumber,
      'barcode': barcode,
      'location': location,
      'status': status,
      'totalQuantity': totalQuantity,
      'availableQuantity': availableQuantity,
      'photoPath': photoPath,
      'value': value,
      'purchaseDate': purchaseDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'userId': userId,
      'userName': userName,
      'isSynced': isSynced ? 1 : 0,
    };
  }

  factory Equipment.fromMap(Map<String, dynamic> map) {
    return Equipment(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      serialNumber: map['serialNumber'] ?? '',
      barcode: map['barcode'],
      location: map['location'] ?? '',
      status: map['status'] ?? 'available',
      totalQuantity: map['totalQuantity'] ?? 1,
      availableQuantity: map['availableQuantity'] ?? 1,
      photoPath: map['photoPath'],
      value: (map['value'] ?? 0).toDouble(),
      purchaseDate: map['purchaseDate'] != null 
          ? DateTime.parse(map['purchaseDate']) 
          : DateTime.now(),
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.parse(map['updatedAt']) 
          : DateTime.now(),
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      isSynced: (map['isSynced'] ?? 1) == 1,
    );
  }

  Equipment copyWith({
    String? id,
    String? name,
    String? category,
    String? description,
    String? serialNumber,
    String? barcode,
    String? location,
    String? status,
    int? totalQuantity,
    int? availableQuantity,
    String? photoPath,
    double? value,
    DateTime? purchaseDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
    String? userName,
    bool? isSynced,
  }) {
    return Equipment(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      serialNumber: serialNumber ?? this.serialNumber,
      barcode: barcode ?? this.barcode,
      location: location ?? this.location,
      status: status ?? this.status,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      availableQuantity: availableQuantity ?? this.availableQuantity,
      photoPath: photoPath ?? this.photoPath,
      value: value ?? this.value,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  bool get isAvailable => availableQuantity > 0;
  bool get isCheckedOut => status == 'checked_out';
  bool get isLowStock => availableQuantity == 0;

  static String generateId() {
    return const Uuid().v4();
  }
}
