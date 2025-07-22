import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../data/note.dart';
import '../data/tag.dart';


class DatabaseService {
  static Database? _database;
  final String _databaseName;

  DatabaseService._internal(this._databaseName);

  factory DatabaseService({String databaseName = 'notes_tag.db'}) {
    return DatabaseService._internal(databaseName);
  }

  factory DatabaseService.forTesting({
    String databaseName = 'note_tag_test.db',
  }) {
    return DatabaseService._internal(databaseName);
  }

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDatabase(name: 'notes_tag.db');
    return _database!;
  }

  Future<Database> getDatabaseTest(String name) async {
    // 根據你的測試代碼，使用 'getDatabaseTest'
    if (_database != null && _database!.isOpen) {
      return _database!;
    }
    _database = await _initDatabase(name: name);
    return _database!;
  }

  Future<Database> _initDatabase({required String name}) async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, name);

    return await openDatabase(
      path,
      version: 1,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onDowngrade: onDatabaseDowngradeDelete,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
    print('資料庫配置: 外鍵已啟用');
  }

  // **** 關鍵修改在這裡：直接創建 V2 的完整 SCHEMA ****
  Future<void> _onCreate(Database db, int version) async {
    // 創建 notes 表 (V2 結構)
    await db.execute('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL, 
        title TEXT NOT NULL,
        content TEXT,
        is_deleted INTEGER NOT NULL DEFAULT 0, 
        create_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
        update_at TEXT
      )
    ''');
    print('資料表 notes (V2) 創建完成');

    await db.execute('''
      CREATE TABLE tags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        color INTEGER NOT NULL,
        create_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
        update_at TEXT
      )
    ''');
    print('資料表 tags 創建完成');

    //這邊製作 note_tags 表 去用id 來關聯 note tags Foreign Key Cascade Delete
    await db.execute('''
      CREATE TABLE note_tags (
        note_id INTEGER NOT NULL REFERENCES notes(id) ON DELETE CASCADE,
        tag_id INTEGER NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
        PRIMARY KEY (note_id, tag_id)
      )
    ''');
    print('資料表 note_tags 創建完成');


    //這邊是做索引 理論可增加速度
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_note_tags_note_id ON note_tags(note_id);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_note_tags_tag_id ON note_tags(tag_id);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_notes_user_id ON notes(user_id);',
    );
    print('索引創建完成');

    print('資料庫 onCreate: V2 完整 Schema 創建完成！');
  }

  // 插入筆記
  Future<int> insertNote(Note note) async {
    final db = await database;
    return await db.insert(
      'notes',
      note.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Note>> getNotesByUserId(
    String userId, {
    bool includeDeleted = false,
  }) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      where: 'user_id = ? ${includeDeleted ? '' : 'AND is_deleted = 0'}',
      whereArgs: [userId],
      orderBy: 'create_at DESC',
    );
    return List.generate(maps.length, (i) => Note.fromMap(maps[i]));
  }


  Future<int> softDeleteNote(String noteId) async {
    final db = await database;
    return await db.update(
      'notes',
      {'is_deleted': 1, 'update_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [noteId],
    );
  }


  Future<int> restoreNote(int noteId) async {
    final db = await database;
    return await db.update(
      'notes',
      {'is_deleted': 0, 'update_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [noteId],
    );
  }


  Future<int> deleteNote(int noteId) async {
    final db = await database;
    return await db.delete('notes', where: 'id = ?', whereArgs: [noteId]);
  }


  Future<int> insertTag(Tag tag) async {
    final db = await database;
    return await db.insert(
      'tags',
      tag.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }


  Future<List<Tag>> getAllTags() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('tags');
    return List.generate(maps.length, (i) => Tag.fromMap(maps[i]));
  }


  Future<int> addTagToNote(int noteId, int tagId) async {
    final db = await database;
    final existing = await db.query(
      'note_tags',
      where: 'note_id = ? AND tag_id = ?',
      whereArgs: [noteId, tagId],
    );
    if (existing.isNotEmpty) {
      print('Note $noteId already has tag $tagId.');
      return 0;
    }
    return await db.insert('note_tags', {'note_id': noteId, 'tag_id': tagId});
  }


  Future<List<Tag>> getTagsForNote(int noteId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT T.* FROM tags AS T
      INNER JOIN note_tags AS NT ON T.id = NT.tag_id
      WHERE NT.note_id = ?
    ''',
      [noteId],
    );
    return List.generate(maps.length, (i) => Tag.fromMap(maps[i]));
  }


  Future<int> removeTagFromNote(int noteId, int tagId) async {
    final db = await database;
    return await db.delete(
      'note_tags',
      where: 'note_id = ? AND tag_id = ?',
      whereArgs: [noteId, tagId],
    );
  }

  Future<int> deleteTag(int tagId) async {
    final db = await database;
    final result = await db.delete('tags', where: 'id = ?', whereArgs: [tagId]);
    print('從 tags 表刪除 ID: $tagId 的標籤，結果: $result');
    return result;
  }

  Future<Note?> getNoteById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Note.fromMap(maps.first);
    }
    return null;
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
    print('資料庫已關閉');
  }
}
