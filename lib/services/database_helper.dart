import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/device_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  static const String _dbName = 'nuetech_devices.db';
  static const int _dbVersion = 1;
  static const String _tableName = 'devices';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        serialNumber TEXT PRIMARY KEY,
        productId TEXT NOT NULL,
        name TEXT,
        addedAt TEXT NOT NULL
      )
    ''');
  }

  /// Insert a device. Returns true if inserted, false if duplicate.
  Future<bool> addDevice(DeviceModel device) async {
    final db = await database;
    try {
      await db.insert(
        _tableName,
        device.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      return true;
    } catch (e) {
      // PRIMARY KEY constraint violation = duplicate
      return false;
    }
  }

  /// Fetch all stored devices, newest first.
  Future<List<DeviceModel>> getAllDevices() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy: 'addedAt DESC',
    );
    return maps.map((map) => DeviceModel.fromMap(map)).toList();
  }

  /// Check if a device already exists by serial number.
  Future<bool> deviceExists(String serialNumber) async {
    final db = await database;
    final result = await db.query(
      _tableName,
      where: 'serialNumber = ?',
      whereArgs: [serialNumber],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  /// Delete a device by serial number.
  Future<void> deleteDevice(String serialNumber) async {
    final db = await database;
    await db.delete(
      _tableName,
      where: 'serialNumber = ?',
      whereArgs: [serialNumber],
    );
  }

  /// Update optional name of a device.
  Future<void> updateDeviceName(String serialNumber, String name) async {
    final db = await database;
    await db.update(
      _tableName,
      {'name': name},
      where: 'serialNumber = ?',
      whereArgs: [serialNumber],
    );
  }

  /// Close the database.
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}

