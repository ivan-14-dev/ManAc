class DailyReport {
  String id;
  DateTime date;
  int totalCheckouts;
  int totalReturns;
  int totalItemsCheckedOut;
  int totalItemsReturned;
  List<String> checkoutIds;
  List<String> returnIds;
  String summary;
  String generatedBy;
  DateTime generatedAt;
  bool isSynced;

  DailyReport({
    required this.id,
    required this.date,
    required this.totalCheckouts,
    required this.totalReturns,
    required this.totalItemsCheckedOut,
    required this.totalItemsReturned,
    required this.checkoutIds,
    required this.returnIds,
    required this.summary,
    required this.generatedBy,
    required this.generatedAt,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'totalCheckouts': totalCheckouts,
      'totalReturns': totalReturns,
      'totalItemsCheckedOut': totalItemsCheckedOut,
      'totalItemsReturned': totalItemsReturned,
      'checkoutIds': checkoutIds,
      'returnIds': returnIds,
      'summary': summary,
      'generatedBy': generatedBy,
      'generatedAt': generatedAt.toIso8601String(),
      'isSynced': isSynced ? 1 : 0,
    };
  }

  factory DailyReport.fromMap(Map<String, dynamic> map) {
    return DailyReport(
      id: map['id'] ?? '',
      date: map['date'] != null 
          ? DateTime.parse(map['date']) 
          : DateTime.now(),
      totalCheckouts: map['totalCheckouts'] ?? 0,
      totalReturns: map['totalReturns'] ?? 0,
      totalItemsCheckedOut: map['totalItemsCheckedOut'] ?? 0,
      totalItemsReturned: map['totalItemsReturned'] ?? 0,
      checkoutIds: List<String>.from(map['checkoutIds'] ?? []),
      returnIds: List<String>.from(map['returnIds'] ?? []),
      summary: map['summary'] ?? '',
      generatedBy: map['generatedBy'] ?? '',
      generatedAt: map['generatedAt'] != null 
          ? DateTime.parse(map['generatedAt']) 
          : DateTime.now(),
      isSynced: (map['isSynced'] ?? 1) == 1,
    );
  }

  DailyReport copyWith({
    String? id,
    DateTime? date,
    int? totalCheckouts,
    int? totalReturns,
    int? totalItemsCheckedOut,
    int? totalItemsReturned,
    List<String>? checkoutIds,
    List<String>? returnIds,
    String? summary,
    String? generatedBy,
    DateTime? generatedAt,
    bool? isSynced,
  }) {
    return DailyReport(
      id: id ?? this.id,
      date: date ?? this.date,
      totalCheckouts: totalCheckouts ?? this.totalCheckouts,
      totalReturns: totalReturns ?? this.totalReturns,
      totalItemsCheckedOut: totalItemsCheckedOut ?? this.totalItemsCheckedOut,
      totalItemsReturned: totalItemsReturned ?? this.totalItemsReturned,
      checkoutIds: checkoutIds ?? this.checkoutIds,
      returnIds: returnIds ?? this.returnIds,
      summary: summary ?? this.summary,
      generatedBy: generatedBy ?? this.generatedBy,
      generatedAt: generatedAt ?? this.generatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
