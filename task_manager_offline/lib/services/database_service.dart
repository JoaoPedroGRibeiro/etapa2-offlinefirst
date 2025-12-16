import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert'; 

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'task_manager_offline.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks(
        id TEXT PRIMARY KEY,
        title TEXT,
        is_completed INTEGER,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_queue(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action TEXT, 
        item_id TEXT,
        payload TEXT,
        created_at INTEGER
      )
    ''');
  }

  Future<void> insertTask(String id, String title) async {
    final db = await database;
    
    await db.insert('tasks', {
      'id': id,
      'title': title,
      'is_completed': 0, 
      'is_synced': 0     
    });

    await addToSyncQueue('CREATE', id, {'id': id, 'title': title, 'is_completed': false});
  }

  Future<List<Map<String, dynamic>>> getTasks() async {
    final db = await database;
    return await db.query('tasks');
  }

  Future<void> updateTaskStatus(String id, bool isCompleted) async {
    final db = await database;

    await db.update(
      'tasks',
      {
        'is_completed': isCompleted ? 1 : 0,
        'is_synced': 0
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    await addToSyncQueue('UPDATE', id, {'is_completed': isCompleted});
  }


  Future<void> addToSyncQueue(String action, String itemId, Map<String, dynamic> payload) async {
    final db = await database;
    await db.insert('sync_queue', {
      'action': action, 
      'item_id': itemId,
      'payload': jsonEncode(payload),
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<Map<String, dynamic>>> getPendingSyncs() async {
    final db = await database;
    return await db.query('sync_queue', orderBy: 'created_at ASC');
  }

  Future<void> clearSyncQueueItem(int id) async {
    final db = await database;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> markTaskAsSynced(String id) async {
    final db = await database;
    await db.update('tasks', {'is_synced': 1}, where: 'id = ?', whereArgs: [id]);
  }
}