class SyncQueueItem {
  String id;
  String action; // 'create', 'update', 'delete'
  String collection;
  Map<String, dynamic> data;
  DateTime createdAt;
  int retryCount;
  String? error;

  SyncQueueItem({
    required this.id,
    required this.action,
    required this.collection,
    required this.data,
    DateTime? createdAt,
    this.retryCount = 0,
    this.error,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'action': action,
      'collection': collection,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
      'retryCount': retryCount,
      'error': error,
    };
  }

  factory SyncQueueItem.fromMap(Map<String, dynamic> map) {
    return SyncQueueItem(
      id: map['id'] ?? '',
      action: map['action'] ?? '',
      collection: map['collection'] ?? '',
      data: Map<String, dynamic>.from(map['data'] ?? {}),
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
      retryCount: map['retryCount'] ?? 0,
      error: map['error'],
    );
  }

  SyncQueueItem copyWith({
    String? id,
    String? action,
    String? collection,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    int? retryCount,
    String? error,
  }) {
    return SyncQueueItem(
      id: id ?? this.id,
      action: action ?? this.action,
      collection: collection ?? this.collection,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      error: error ?? this.error,
    );
  }
}
