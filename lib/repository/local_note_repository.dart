import 'dart:async';

import 'package:dart_either/dart_either.dart';

import '../abstract_class/Failure.dart';
import '../abstract_class/note_repository.dart';
import '../data/note.dart';
import '../db/database_service.dart';

class LocalNoteRepository implements NoteRepository {
  final DatabaseService _dbService;

  LocalNoteRepository(this._dbService);

  @override
  Stream<List<Note>> watchAll(String userId) {
    final StreamController<List<Note>> _notesController =
        StreamController<List<Note>>.broadcast();

    _dbService
        .getNotesByUserId(userId)
        .then((notes) {
          _notesController.add(notes);
        })
        .catchError((e) {
          _notesController.addError(
            DatabaseFailure('Failed to load initial notes: $e'),
          );
        });

    return _notesController.stream;
  }

  @override
  Future<Either<Failure, Note>> save(Note note) async {
    try {
      // 假設 _dbService.insertNote(note) 會返回插入後筆記的 ID
      final id = await _dbService.insertNote(note);

      // 創建一個帶有新 ID 的 Note 物件
      final savedNote = note.copyWith(id: id);

      // 操作成功，將結果包裝在 Right 中
      return Right(savedNote);
    } catch (e) {
      print('Local Note Save Error: $e');
      return Left(DatabaseFailure('Failed to save note: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> softDelete(String id) async {
    try {
      final rowsAffected = await _dbService.softDeleteNote(id);
      if (rowsAffected > 0) {
        return Right(true); // Success: Note found and soft-deleted.
      } else {
        return Left(
          DatabaseFailure(
            'Note with ID $id not found for soft deletion or already deleted.',
          ),
        );
      }
    } catch (e) {
      // Catch-all for unexpected database errors.
      print('Local Note Soft Delete Error: $e');
      return Left(
        DatabaseFailure('Failed to soft delete note: ${e.toString()}'),
      );
    }
  }
}

extension NoteCopyWith on Note {
  Note copyWith({
    int? id,
    String? userId,
    String? title,
    String? content,
    int? isDeleted,
    String? createdAt,
    String? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
