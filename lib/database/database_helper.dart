import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'app_envio.db');

    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE pending_uploads (
        id TEXT PRIMARY KEY,
        image_path TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        created_at INTEGER NOT NULL,
        status TEXT NOT NULL,
        error_message TEXT,
        firebase_url TEXT
      )
    ''');
  }

  Future<int> insertPendingUpload(Map<String, dynamic> upload) async {
    final db = await database;
    return await db.insert(
      'pending_uploads',
      upload,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getPendingUploads() async {
    final db = await database;
    return await db.query(
      'pending_uploads',
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'created_at ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getPendingAndFailedUploads() async {
    final db = await database;
    return await db.query(
      'pending_uploads',
      where: 'status IN (?, ?)',
      whereArgs: ['pending', 'failed'],
      orderBy: 'created_at ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getAllUploads() async {
    final db = await database;
    return await db.query('pending_uploads', orderBy: 'created_at DESC');
  }

  Future<int> updateUploadStatus(
    String id,
    String status, {
    String? errorMessage,
    String? firebaseUrl,
  }) async {
    final db = await database;
    final updateData = <String, dynamic>{'status': status};

    if (errorMessage != null) updateData['error_message'] = errorMessage;
    if (firebaseUrl != null) updateData['firebase_url'] = firebaseUrl;

    return await db.update(
      'pending_uploads',
      updateData,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> resetUploadingToPending() async {
    final db = await database;
    return await db.update(
      'pending_uploads',
      {'status': 'pending', 'error_message': null},
      where: 'status = ?',
      whereArgs: ['uploading'],
    );
  }

  Future<int> deleteUpload(String id) async {
    final db = await database;
    return await db.delete('pending_uploads', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteCompletedUploads() async {
    final db = await database;
    return await db.delete(
      'pending_uploads',
      where: 'status = ?',
      whereArgs: ['completed'],
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
