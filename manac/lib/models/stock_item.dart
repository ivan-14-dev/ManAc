class StockItem {
  String id;
  String name;
  String category;
  int quantity;
  int minQuantity;
  String unit;
  double price;
  String? description;
  String? barcode;
  String location;
  DateTime createdAt;
  DateTime updatedAt;
  bool isSynced;
  String? firebaseId;

  StockItem({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.minQuantity,
    required this.unit,
    required this.price,
    this.description,
    this.barcode,
    this.location = 'Main Warehouse',
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isSynced = false,
    this.firebaseId,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'quantity': quantity,
      'minQuantity': minQuantity,
      'unit': unit,
      'price': price,
      'description': description,
      'barcode': barcode,
      'location': location,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isSynced': isSynced ? 1 : 0,
      'firebaseId': firebaseId ?? id,
    };
  }

  factory StockItem.fromMap(Map<String, dynamic> map) {
    return StockItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      quantity: map['quantity'] ?? 0,
      minQuantity: map['minQuantity'] ?? 0,
      unit: map['unit'] ?? 'pcs',
      price: (map['price'] ?? 0).toDouble(),
      description: map['description'],
      barcode: map['barcode'],
      location: map['location'] ?? 'Main Warehouse',
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.parse(map['updatedAt']) 
          : DateTime.now(),
      isSynced: (map['isSynced'] ?? 1) == 1,
      firebaseId: map['firebaseId'] ?? map['id'],
    );
  }

  StockItem copyWith({
    String? id,
    String? name,
    String? category,
    int? quantity,
    int? minQuantity,
    String? unit,
    double? price,
    String? description,
    String? barcode,
    String? location,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    String? firebaseId,
  }) {
    return StockItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      minQuantity: minQuantity ?? this.minQuantity,
      unit: unit ?? this.unit,
      price: price ?? this.price,
      description: description ?? this.description,
      barcode: barcode ?? this.barcode,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      firebaseId: firebaseId ?? this.firebaseId,
    );
  }

  bool get isLowStock => quantity <= minQuantity;
}
