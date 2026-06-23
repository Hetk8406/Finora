import 'package:sqflite/sqflite.dart';
import '../models/estimate.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('finora.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4, // Bumped version for userId column
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE estimates (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL,
        companyName TEXT NOT NULL,
        address TEXT NOT NULL,
        email TEXT NOT NULL,
        businessType TEXT NOT NULL,
        ownerName TEXT NOT NULL,
        phone TEXT NOT NULL,
        turnover REAL NOT NULL,
        currency TEXT NOT NULL,
        estimatedFee REAL NOT NULL,
        feePercentage REAL NOT NULL,
        reportsData TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 4) {
      // Check if userId column exists
      var res = await db.rawQuery("PRAGMA table_info(estimates)");
      bool hasUserId = res.any((element) => element['name'] == 'userId');
      if (!hasUserId) {
        await db.execute('ALTER TABLE estimates ADD COLUMN userId TEXT DEFAULT ""');
      }
    }
  }

  Future<int> create(Estimate estimate) async {
    final db = await instance.database;
    return await db.insert('estimates', estimate.toMap());
  }

  Future<Estimate?> readOne(int id) async {
    final db = await instance.database;
    final maps = await db.query('estimates', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return Estimate.fromMap(maps.first);
    return null;
  }

  Future<List<Estimate>> readAll(String userId) async {
    final db = await instance.database;
    // We only filter if userId is provided or we can filter all if needed
    final res = await db.query('estimates', 
      where: userId.isNotEmpty ? 'userId = ?' : null, 
      whereArgs: userId.isNotEmpty ? [userId] : null,
      orderBy: 'createdAt DESC');
    return res.map((json) => Estimate.fromMap(json)).toList();
  }

  Future<int> update(Estimate estimate) async {
    final db = await instance.database;
    return await db.update('estimates', estimate.toMap(), where: 'id = ?', whereArgs: [estimate.id]);
  }

  Future<int> delete(int id) async {
    final db = await instance.database;
    return await db.delete('estimates', where: 'id = ?', whereArgs: [id]);
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
