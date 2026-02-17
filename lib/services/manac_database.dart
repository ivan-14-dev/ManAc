// ========================================
// Service de base de données SQLite
// Gère le stockage local via SQLite (manac.sqlite)
// ========================================

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/equipment.dart';
import '../models/equipment_checkout.dart';
import '../models/activity.dart';
import '../models/stock_item.dart';

class ManacDatabase {
  static final ManacDatabase _instance = ManacDatabase._internal();
  static Database? _database;

  factory ManacDatabase() => _instance;
  ManacDatabase._internal();

  // Database name
  static const String _databaseName = 'manac.sqlite';
  static const int _databaseVersion = 1;

  // Table names
  static const String tableEquipment = 'equipment';
  static const String tableCheckouts = 'equipment_checkouts';
  static const String tableActivities = 'activities';
  static const String tableStockItems = 'stock_items';
  static const String tableStockMovements = 'stock_movements';
  static const String tableSyncQueue = 'sync_queue';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Equipment table
    await db.execute('''
      CREATE TABLE $tableEquipment (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        description TEXT,
        serialNumber TEXT NOT NULL,
        barcode TEXT,
        location TEXT NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 0,
        availableQuantity INTEGER NOT NULL DEFAULT 0,
        status TEXT DEFAULT 'available',
        photoPath TEXT,
        value REAL DEFAULT 0,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        isSynced INTEGER DEFAULT 0,
        firebaseId TEXT
      )
    ''');

    // Equipment Checkouts table
    await db.execute('''
      CREATE TABLE $tableCheckouts (
        id TEXT PRIMARY KEY,
        equipmentId TEXT NOT NULL,
        equipmentName TEXT NOT NULL,
        equipmentPhotoPath TEXT,
        borrowerName TEXT NOT NULL,
        borrowerCni TEXT NOT NULL,
        borrowerEmail TEXT,
        cniPhotoPath TEXT,
        destinationRoom TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        checkoutTime TEXT NOT NULL,
        returnTime TEXT,
        isReturned INTEGER DEFAULT 0,
        notes TEXT,
        userId TEXT NOT NULL,
        userName TEXT NOT NULL,
        isSynced INTEGER DEFAULT 0
      )
    ''');

    // Activities table
    await db.execute('''
      CREATE TABLE $tableActivities (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        userId TEXT,
        userName TEXT,
        metadata TEXT,
        createdAt TEXT NOT NULL,
        isSynced INTEGER DEFAULT 0
      )
    ''');

    // Stock Items table
    await db.execute('''
      CREATE TABLE $tableStockItems (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        description TEXT,
        quantity INTEGER NOT NULL DEFAULT 0,
        minQuantity INTEGER NOT NULL DEFAULT 0,
        unit TEXT,
        location TEXT,
        barcode TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        isSynced INTEGER DEFAULT 0,
        firebaseId TEXT
      )
    ''');

    // Stock Movements table
    await db.execute('''
      CREATE TABLE $tableStockMovements (
        id TEXT PRIMARY KEY,
        itemId TEXT NOT NULL,
        itemName TEXT NOT NULL,
        type TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        reason TEXT,
        userId TEXT,
        userName TEXT,
        createdAt TEXT NOT NULL,
        isSynced INTEGER DEFAULT 0
      )
    ''');

    // Sync Queue table
    await db.execute('''
      CREATE TABLE $tableSyncQueue (
        id TEXT PRIMARY KEY,
        action TEXT NOT NULL,
        collection TEXT NOT NULL,
        data TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        retryCount INTEGER DEFAULT 0,
        lastError TEXT
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_equipment_category ON $tableEquipment(category)');
    await db.execute('CREATE INDEX idx_checkouts_returned ON $tableCheckouts(isReturned)');
    await db.execute('CREATE INDEX idx_activities_type ON $tableActivities(type)');
    await db.execute('CREATE INDEX idx_stock_category ON $tableStockItems(category)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database migrations here
  }

  // ==================== Equipment Operations ====================

  Future<int> insertEquipment(Equipment equipment) async {
    final db = await database;
    return await db.insert(
      tableEquipment,
      equipment.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateEquipment(Equipment equipment) async {
    final db = await database;
    return await db.update(
      tableEquipment,
      equipment.toMap(),
      where: 'id = ?',
      whereArgs: [equipment.id],
    );
  }

  Future<int> deleteEquipment(String id) async {
    final db = await database;
    return await db.delete(
      tableEquipment,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Equipment?> getEquipment(String id) async {
    final db = await database;
    final maps = await db.query(
      tableEquipment,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Equipment.fromMap(maps.first);
  }

  Future<List<Equipment>> getAllEquipment() async {
    final db = await database;
    final maps = await db.query(tableEquipment, orderBy: 'name ASC');
    return maps.map((map) => Equipment.fromMap(map)).toList();
  }

  Future<List<Equipment>> searchEquipment(String query) async {
    final db = await database;
    final maps = await db.query(
      tableEquipment,
      where: 'name LIKE ? OR category LIKE ? OR serialNumber LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
    );
    return maps.map((map) => Equipment.fromMap(map)).toList();
  }

  // ==================== Checkout Operations ====================

  Future<int> insertCheckout(EquipmentCheckout checkout) async {
    final db = await database;
    return await db.insert(
      tableCheckouts,
      checkout.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateCheckout(EquipmentCheckout checkout) async {
    final db = await database;
    return await db.update(
      tableCheckouts,
      checkout.toMap(),
      where: 'id = ?',
      whereArgs: [checkout.id],
    );
  }

  Future<int> deleteCheckout(String id) async {
    final db = await database;
    return await db.delete(
      tableCheckouts,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<EquipmentCheckout?> getCheckoutById(String id) async {
    final db = await database;
    final maps = await db.query(
      tableCheckouts,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return EquipmentCheckout.fromMap(maps.first);
  }

  Future<List<EquipmentCheckout>> getAllCheckouts() async {
    final db = await database;
    final maps = await db.query(tableCheckouts, orderBy: 'checkoutTime DESC');
    return maps.map((map) => EquipmentCheckout.fromMap(map)).toList();
  }

  Future<List<EquipmentCheckout>> getActiveCheckouts() async {
    final db = await database;
    final maps = await db.query(
      tableCheckouts,
      where: 'isReturned = ?',
      whereArgs: [0],
      orderBy: 'checkoutTime DESC',
    );
    return maps.map((map) => EquipmentCheckout.fromMap(map)).toList();
  }

  Future<List<EquipmentCheckout>> getReturnedCheckouts() async {
    final db = await database;
    final maps = await db.query(
      tableCheckouts,
      where: 'isReturned = ?',
      whereArgs: [1],
      orderBy: 'checkoutTime DESC',
    );
    return maps.map((map) => EquipmentCheckout.fromMap(map)).toList();
  }

  // ==================== Activity Operations ====================

  Future<int> insertActivity(Activity activity) async {
    final db = await database;
    return await db.insert(
      tableActivities,
      activity.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Activity>> getAllActivities() async {
    final db = await database;
    final maps = await db.query(tableActivities, orderBy: 'createdAt DESC');
    return maps.map((map) => Activity.fromMap(map)).toList();
  }

  // ==================== Stock Operations ====================

  Future<int> insertStockItem(StockItem item) async {
    final db = await database;
    return await db.insert(
      tableStockItems,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateStockItem(StockItem item) async {
    final db = await database;
    return await db.update(
      tableStockItems,
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<List<StockItem>> getAllStockItems() async {
    final db = await database;
    final maps = await db.query(tableStockItems, orderBy: 'name ASC');
    return maps.map((map) => StockItem.fromMap(map)).toList();
  }

  // ==================== Sync Queue Operations ====================

  Future<int> insertSyncItem(Map<String, dynamic> item) async {
    final db = await database;
    return await db.insert(tableSyncQueue, item);
  }

  Future<List<Map<String, dynamic>>> getPendingSyncItems() async {
    final db = await database;
    return await db.query(tableSyncQueue, orderBy: 'createdAt ASC');
  }

  Future<int> deleteSyncItem(String id) async {
    final db = await database;
    return await db.delete(
      tableSyncQueue,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== Utility Operations ====================

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete(tableEquipment);
    await db.delete(tableCheckouts);
    await db.delete(tableActivities);
    await db.delete(tableStockItems);
    await db.delete(tableStockMovements);
    await db.delete(tableSyncQueue);
  }

  Future<Map<String, int>> getStatistics() async {
    final db = await database;
    
    final equipmentCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $tableEquipment'),
    ) ?? 0;
    
    final activeCheckoutsCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $tableCheckouts WHERE isReturned = 0'),
    ) ?? 0;
    
    final returnedCheckoutsCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $tableCheckouts WHERE isReturned = 1'),
    ) ?? 0;
    
    final pendingSyncCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $tableSyncQueue'),
    ) ?? 0;

    return {
      'equipment': equipmentCount,
      'activeCheckouts': activeCheckoutsCount,
      'returnedCheckouts': returnedCheckoutsCount,
      'pendingSync': pendingSyncCount,
    };
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
