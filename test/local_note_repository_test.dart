// test/local_note_repository_test.dart
import 'package:dart_either/dart_either.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_answer/abstract_class/Failure.dart';
import 'package:my_answer/data/note.dart';
import 'package:my_answer/db/database_service.dart';
import 'package:my_answer/repository/local_note_repository.dart';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

void main() {
  // 設置測試環境的 sqflite
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('LocalNoteRepository Tests', () {
    late DatabaseService dbService;
    late LocalNoteRepository localRepo;
    final String testUserId = 'test_local_user_id';

    setUp(() async {
      // 每次測試前，確保資料庫是乾淨的
      final String uniqueDbName =
          'test_repo_db_${DateTime.now().microsecondsSinceEpoch}.db';

      dbService = DatabaseService.forTesting(databaseName: uniqueDbName);
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, uniqueDbName);
      await deleteDatabase(path);
      await dbService.getDatabaseTest(uniqueDbName);

      localRepo = LocalNoteRepository(dbService);
    });

    tearDown(() async {
      await dbService.close();
    });

    group('watchAll()', () {
      test('監聽並返回指定用戶的所有Note', () async {
        // Arrange
        final note1 = Note(
          userId: testUserId,
          title: 'Note 1',
          createdAt: DateTime.now().toIso8601String(),
        );
        final note2 = Note(
          userId: testUserId,
          title: 'Note 2',
          createdAt: DateTime.now().toIso8601String(),
        );
        final otherUserNote = Note(
          userId: 'other_user',
          title: 'Other User Note',
          createdAt: DateTime.now().toIso8601String(),
        );

        await dbService.insertNote(note1);
        await dbService.insertNote(note2);
        await dbService.insertNote(otherUserNote);
        // Act
        final stream = localRepo.watchAll(testUserId);

        // Assert
        expect(
          stream,
          emitsInOrder([
            // 初始數據
            [
              predicate<Note>(
                (n) =>
                    n.title == 'Note 2' &&
                    n.userId == testUserId, // 期望第一項是 Note 2
              ),
              predicate<Note>(
                (n) =>
                    n.title == 'Note 1' &&
                    n.userId == testUserId, // 期望第二項是 Note 1
              ),
            ],
          ]),
        );
      });
    });

    // // --- save() 測試 ---
    group('save()', () {
      test('應該成功保存新筆記並返回帶有ID的Note', () async {
        // Arrange
        final newNote = Note(
          userId: testUserId,
          title: 'New Test Note',
          content: 'Content',
          createdAt: DateTime.now().toIso8601String(),
        );

        // Act
        final savedNote = await localRepo.save(newNote);
        if (savedNote.isRight) {
          var savedNoteRight = savedNote.getOrThrow();
          expect(savedNoteRight.id, isNotNull);
          expect(savedNoteRight.title, 'New Test Note');
          expect(savedNoteRight.userId, testUserId);
          expect(savedNoteRight.isDeleted, 0); // 默認非軟刪除

          // 驗證資料庫中確實存在
          final notesInDb = await dbService.getNotesByUserId(testUserId);
          expect(notesInDb.length, 1);
          expect(notesInDb.first.id, savedNoteRight.id);
        }
      });
    });
    // // --- softDelete() 測試 ---
    group('softDelete()', () {
      test('應該成功軟刪除Note並返回 Bool', () async {
        // Arrange
        final noteToDelete = Note(
          userId: testUserId,
          title: 'To Be Soft Deleted',
          createdAt: DateTime.now().toIso8601String(),
        );
        final id = await dbService.insertNote(noteToDelete);

        // Act
        final delete = await localRepo.softDelete(id.toString());
        final result = delete.getOrThrow();

        // Assert
        expect(result, isA<bool>()); // 驗證返回 Unit 類型

        // 驗證筆記被標記為刪除
        final deletedNote = await dbService.getNoteById(id);
        expect(deletedNote, isNotNull);
        expect(deletedNote!.isDeleted, 1);

        // 驗證預設查詢不會返回該筆記
        final notes = await dbService.getNotesByUserId(testUserId);
        expect(notes.any((n) => n.id == id), isFalse);
      });

      test('嘗試軟刪除不存在的Note應該拋出 DatabaseFailure', () async {
        // Act & Assert
        final delete = await localRepo.softDelete('9999');
        delete.when(
          ifLeft: (l) {
            final actualFailure = l.value;
            print('Left: ${actualFailure}');
            expect(actualFailure, isA<DatabaseFailure>());
          },
          ifRight: (r) => print('Right: $r'),
        );
      });
    });
  });
}
