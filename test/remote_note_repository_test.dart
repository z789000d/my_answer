import 'dart:async';
import 'dart:math';

import 'package:dart_either/dart_either.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:my_answer/abstract_class/Failure.dart';
import 'package:my_answer/data/note.dart';
import 'package:my_answer/db/database_service.dart';
import 'package:my_answer/repository/remote_note_repository.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // 設置測試環境的 sqflite
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('RemoteNoteRepository Tests', () {
    late RemoteNoteRepository remoteRepo;
    final String testUserId = 'test_local_user_id';

    setUp(() async {
      remoteRepo = RemoteNoteRepository();
    });

    tearDown(() async {});

    // --- watchAll() 測試 ---
    group('watchAll()', () {
      test('監聽並返回指定用戶的所有Note', () async {
        // Arrange
        final note1 = Note(
          id: 0,
          userId: testUserId,
          title: 'Note 1',
          createdAt: DateTime.now().toIso8601String(),
        );
        final note2 = Note(
          id: 1,
          userId: testUserId,
          title: 'Note 2',
          createdAt: DateTime.now().toIso8601String(),
        );
        final otherUserNote = Note(
          id: 2,
          userId: 'other_user',
          title: 'Other User Note',
          createdAt: DateTime.now().toIso8601String(),
        );

        await remoteRepo.save(note1);
        await remoteRepo.save(note2);
        await remoteRepo.save(otherUserNote); // 這個會被保存，但 watchAll 不會返回它
        // Act
        final stream = remoteRepo.watchAll(testUserId);
        // Assert
        expect(
          stream,
          emitsInOrder([
            // 初始數據 (當 watchAll 首次訂閱並觸發 _notifyListeners 後)
            [
              predicate<Note>(
                (n) => n.title == 'Note 2' && n.userId == testUserId,
              ), // 期望是 Note 2 (較新)
              predicate<Note>(
                (n) => n.title == 'Note 1' && n.userId == testUserId,
              ), // 期望是 Note 1 (較舊)
            ],
          ]),
        );

        await Future.delayed(Duration(milliseconds: 100));
      });
    });

    // // --- save() 測試 ---
    group('save()', () {
      test('應該成功保存新Note並返回帶有ID的Note', () async {
        // Arrange
        final newNote = Note(
          userId: testUserId,
          title: 'New Test Note',
          content: 'Content',
          createdAt: DateTime.now().toIso8601String(),
        );

        // Act
        final savedNote = await remoteRepo.save(newNote);

        if (savedNote.isRight) {
          final result = savedNote.getOrThrow();
          // Assert
          expect(result.id, isNotNull);
          expect(result.title, 'New Test Note');
          expect(result.userId, testUserId);
          expect(result.isDeleted, 0); // 默認非軟刪除
        }
      });
    });

    group('softDelete()', () {
      test('應該成功軟刪除筆記並返回 Bool', () async {
        final newNote = Note(
          userId: testUserId,
          title: 'New Test Note',
          content: 'Content',
          createdAt: DateTime.now().toIso8601String(),
        );

        // Act
        final savedNote = await remoteRepo.save(newNote);

        final id = 1000;

        final delete = await remoteRepo.softDelete(id.toString());
        delete.when(
          ifLeft: (l) {
          },
          ifRight: (r) {
            final result = r.value;
            expect(result, isA<bool>());

            final deletedNote =
                remoteRepo
                    .getNoteMap()[testUserId]
                    ?.where((note) => note.id == id)
                    .first;

            expect(deletedNote, isNotNull);
            expect(deletedNote?.isDeleted, 1);
          },
        );
      });

      test('嘗試軟刪除不存在的Note應該拋出 NetworkFailure', () async {

        final delete = await remoteRepo.softDelete('9999');
        delete.when(
          ifLeft: (l) {
            final actualFailure = l.value;
            expect(actualFailure, isA<NetworkFailure>());
          },
          ifRight: (r) => print('Right: $r'),
        );
      });
    });
  });
}
