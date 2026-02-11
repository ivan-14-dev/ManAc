class Activity {
  String id;
  String type; // 'stock_in', 'stock_out', 'stock_adjustment', 'sync', 'login', 'logout'
  String title;
  String description;
  DateTime timestamp;
  String? userId;
  String? userName;
  Map<String, dynamic>? metadata;
  bool isSynced;

  Activity({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    DateTime? timestamp,
    this.userId,
    this.userName,
    this.metadata,
    this.isSynced = false,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
      'userName': userName,
      'metadata': metadata,
      'isSynced': isSynced ? 1 : 0,
    };
  }

  factory Activity.fromMap(Map<String, dynamic> map) {
    return Activity(
      id: map['id'] ?? '',
      type: map['type'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      timestamp: map['timestamp'] != null 
          ? DateTime.parse(map['timestamp']) 
          : DateTime.now(),
      userId: map['userId'],
      userName: map['userName'],
      metadata: map['metadata'] != null 
          ? Map<String, dynamic>.from(map['metadata']) 
          : null,
      isSynced: (map['isSynced'] ?? 1) == 1,
    );
  }

  Activity copyWith({
    String? id,
    String? type,
    String? title,
    String? description,
    DateTime? timestamp,
    String? userId,
    String? userName,
    Map<String, dynamic>? metadata,
    bool? isSynced,
  }) {
    return Activity(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      metadata: metadata ?? this.metadata,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
