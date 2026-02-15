import 'package:uuid/uuid.dart';

class EquipmentCheckout {
  String id;
  String equipmentId;
  String equipmentName;
  String equipmentPhotoPath;
  String borrowerName;
  String borrowerCni;
  String cniPhotoPath;
  String destinationRoom;
  int quantity;
  DateTime checkoutTime;
  DateTime? returnTime;
  bool isReturned;
  String? notes;
  String userId;
  String userName;
  bool isSynced;

  EquipmentCheckout({
    required this.id,
    required this.equipmentId,
    required this.equipmentName,
    required this.equipmentPhotoPath,
    required this.borrowerName,
    required this.borrowerCni,
    required this.cniPhotoPath,
    required this.destinationRoom,
    required this.quantity,
    required this.checkoutTime,
    this.returnTime,
    this.isReturned = false,
    this.notes,
    required this.userId,
    required this.userName,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'equipmentId': equipmentId,
      'equipmentName': equipmentName,
      'equipmentPhotoPath': equipmentPhotoPath,
      'borrowerName': borrowerName,
      'borrowerCni': borrowerCni,
      'cniPhotoPath': cniPhotoPath,
      'destinationRoom': destinationRoom,
      'quantity': quantity,
      'checkoutTime': checkoutTime.toIso8601String(),
      'returnTime': returnTime?.toIso8601String(),
      'isReturned': isReturned ? 1 : 0,
      'notes': notes,
      'userId': userId,
      'userName': userName,
      'isSynced': isSynced ? 1 : 0,
    };
  }

  factory EquipmentCheckout.fromMap(Map<String, dynamic> map) {
    return EquipmentCheckout(
      id: map['id'] ?? '',
      equipmentId: map['equipmentId'] ?? '',
      equipmentName: map['equipmentName'] ?? '',
      equipmentPhotoPath: map['equipmentPhotoPath'] ?? '',
      borrowerName: map['borrowerName'] ?? '',
      borrowerCni: map['borrowerCni'] ?? '',
      cniPhotoPath: map['cniPhotoPath'] ?? '',
      destinationRoom: map['destinationRoom'] ?? '',
      quantity: map['quantity'] ?? 1,
      checkoutTime: map['checkoutTime'] != null 
          ? DateTime.parse(map['checkoutTime']) 
          : DateTime.now(),
      returnTime: map['returnTime'] != null 
          ? DateTime.parse(map['returnTime']) 
          : null,
      isReturned: (map['isReturned'] ?? 0) == 1,
      notes: map['notes'],
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      isSynced: (map['isSynced'] ?? 1) == 1,
    );
  }

  EquipmentCheckout copyWith({
    String? id,
    String? equipmentId,
    String? equipmentName,
    String? equipmentPhotoPath,
    String? borrowerName,
    String? borrowerCni,
    String? cniPhotoPath,
    String? destinationRoom,
    int? quantity,
    DateTime? checkoutTime,
    DateTime? returnTime,
    bool? isReturned,
    String? notes,
    String? userId,
    String? userName,
    bool? isSynced,
  }) {
    return EquipmentCheckout(
      id: id ?? this.id,
      equipmentId: equipmentId ?? this.equipmentId,
      equipmentName: equipmentName ?? this.equipmentName,
      equipmentPhotoPath: equipmentPhotoPath ?? this.equipmentPhotoPath,
      borrowerName: borrowerName ?? this.borrowerName,
      borrowerCni: borrowerCni ?? this.borrowerCni,
      cniPhotoPath: cniPhotoPath ?? this.cniPhotoPath,
      destinationRoom: destinationRoom ?? this.destinationRoom,
      quantity: quantity ?? this.quantity,
      checkoutTime: checkoutTime ?? this.checkoutTime,
      returnTime: returnTime ?? this.returnTime,
      isReturned: isReturned ?? this.isReturned,
      notes: notes ?? this.notes,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  static String generateId() {
    return const Uuid().v4();
  }
}
