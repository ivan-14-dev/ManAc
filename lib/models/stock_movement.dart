class StockMovement {
  String id;
  String stockItemId;
  String type; // 'in', 'out', 'adjustment'
  int quantity;
  String? reason;
  String? reference;
  DateTime date;
  String? userId;
  String? userName;
  bool isSynced;

  StockMovement({
    required this.id,
    required this.stockItemId,
    required this.type,
    required this.quantity,
    this.reason,
    this.reference,
    DateTime? date,
    this.userId,
    this.userName,
    this.isSynced = false,
  }) : date = date ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'stockItemId': stockItemId,
      'type': type,
      'quantity': quantity,
      'reason': reason,
      'reference': reference,
      'date': date.toIso8601String(),
      'userId': userId,
      'userName': userName,
      'isSynced': isSynced ? 1 : 0,
    };
  }

  factory StockMovement.fromMap(Map<String, dynamic> map) {
    return StockMovement(
      id: map['id'] ?? '',
      stockItemId: map['stockItemId'] ?? '',
      type: map['type'] ?? 'adjustment',
      quantity: map['quantity'] ?? 0,
      reason: map['reason'],
      reference: map['reference'],
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      userId: map['userId'],
      userName: map['userName'],
      isSynced: (map['isSynced'] ?? 1) == 1,
    );
  }

  StockMovement copyWith({
    String? id,
    String? stockItemId,
    String? type,
    int? quantity,
    String? reason,
    String? reference,
    DateTime? date,
    String? userId,
    String? userName,
    bool? isSynced,
  }) {
    return StockMovement(
      id: id ?? this.id,
      stockItemId: stockItemId ?? this.stockItemId,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      reason: reason ?? this.reason,
      reference: reference ?? this.reference,
      date: date ?? this.date,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
